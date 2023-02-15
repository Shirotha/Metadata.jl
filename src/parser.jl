function findlineindex(str, pos)
    lines = split(str, '\n')
    line = 1
    while pos > length(lines[line])
        pos -= length(lines[line])
        line += 1
        line < length(lines) || return line, pos
    end
    return line, pos
end

string(str::AbstractString, r::StrRange) = String(strip(str[(r.offset + 1):(r.offset + r.length)]))
string(str::AbstractString, r::StrRange, max::Int) = string(str, StrRange(min(r.offset, max), min(r.offset + r.length - 1, max - 1) - r.offset + 1, r.escapecount))
symbol(str::AbstractString, r::StrRange) = Symbol(string(str, r))
symbol(str::AbstractString, r::StrRange, max::Int) = Symbol(string(str, r, max))

const CountToken = Numeric(UInt32)
const InternalStringToken = StringToken(StrRange)

EndedToken(endchar; T = InternalStringToken) = WrapLocalOpts(LocalOpts(endchar, false, 0x0, 0x0, false, false), T)
const WordToken = EndedToken(' ')
const ValueToken = EndedToken('\n')
const ListToken = EndedToken(',')
const SkipToTail = EndedToken('(')
const PropertyNameToken = EndedToken(':')

struct Indent <: AbstractToken{Tuple{Int, Int}}
    tablength::Int
end

function tryparsenext(ind::Indent, str, i, len)
    @debug begin
        line, pos = findlineindex(str, i)
        "$ind at $line:$pos"
    end

    i > len && return Nullable{Int}(), i
    indent = 0
    lines = 0
    while i <= len
        ord = codeunit(str, i)
        if ord == 0x20
            indent += 1
        elseif ord == 0x9
            indent += ind.tablength
        elseif ord == 0xa
            indent = 0
            lines += 1
        else
            break
        end

        i += 1
    end

    @debug begin
        line, pos = findlineindex(str, i) 
        "$ind ends at $line:$pos matching ($indent, $lines)"
    end
    return Nullable((indent, lines)), i
end

const IndentToken = Indent(4)

struct Parented{T} <: AbstractToken{T}
    lparen::Char
    rparen::Char
end
Parented(T, lparen, rparen) = Parented{T}(lparen, rparen)

function tryparsenext(par::Parented{T}, str, i, len) where T
    @debug begin
        line, pos = findlineindex(str, i)
        "$par at $line:$pos"
    end

    len <= i + 1 && return Nullable{T}(), i

    state = iterate(str, i)
    isnothing(state) && return Nullable{T}(), i
    state[1] != par.lparen && return Nullable{T}(), i
    
    i = state[2]
    result, i = tryparsenext(EndedToken(par.rparen; T = StringToken(T)), str, i, len)

    state = iterate(str, i)
    state[1] != par.rparen && return Nullable{T}(), i
    i = state[2]

    @debug begin
        @assert result.hasvalue
        line, pos = findlineindex(str, i)
        val = string(str, result.value)
        "$par ends at $line:$pos matching $(par.lparen)$(val)$(par.rparen)"
    end
    return result, i
end

const TailToken = Parented(StrRange, '(', ')')
const PathToken = Parented(StrRange, '[', ']')
const IncludeToken = Parented(StrRange, '<', '>')

struct PropertyToken <: AbstractToken{Pair{Symbol, String}} end

function tryparsenext(prop::PropertyToken, str, i, len)
    @debug begin
        line, pos = findlineindex(str, i)
        "$prop at $line:$pos"
    end
    
    T = Nullable{Pair{Symbol, String}}

    name, i = tryparsenext(PropertyNameToken, str, i, len)
    name.hasvalue || return T(), i
    n_str = string(str, name.value)
    '\n' in n_str && return T(), i
    n = Symbol(n_str)

    state = iterate(str, i)
    isnothing(state) && return T(), i
    colon, i = state
    colon == PropertyNameToken.opts.endchar || return T(), i

    value, i = tryparsenext(ValueToken, str, i, len)
    value.hasvalue || return T(), i
    v = string(str, value.value)

    @debug begin
        line, pos = findlineindex(str, i)
        "$prop ends at $line:$pos matching $n => $v"
    end
    return T(n => v), i
end

struct ItemToken <: AbstractToken{Item}
    indent::Int
    pwd::Nullable{String}
end

function tryparsenext(item::ItemToken, str, i, len, opts=TextParse.default_opts)
    @debug begin
        line, pos = findlineindex(str, i)
        "$item at $line:$pos"
    end

    normalize(x) = x
    normalize(x::Nullable) = x.hasvalue ? x.value : 1
    splitsymbols(min, max, delim) = Symbol.(filter(!isempty, strip.(split(str[min:(max-1)], delim))))
    splitsymbols(r::StrRange, delim) = splitsymbols(r.offset + 1, r.offset + r.length + 1, delim)

    path, j = tryparsenext(PathToken, str, i, len)
    
    words = Symbol[]
    count = 1
    pwd = item.pwd
    name::Union{String, Symbol} = ""
    if path.hasvalue
        name = string(str, path.value)
        pwd.hasvalue && (pwd = Nullable(joinpath(pwd.value, name)))
        i = j
    else
        count, i = tryparsenext(CountToken, str, i, len, opts)

        _, j = tryparsenext(SkipToTail, str, i, len)

        words = splitsymbols(i, j, ' ')
        i = j
        
        isempty(words) && return Nullable{Item}(), i
        name = pop!(words)

        tmp, j = tryparsenext(TailToken, str, i, len)
        if tmp.hasvalue
            append!(words, splitsymbols(tmp.value, ','))
        end
        i = j
    end

    children = Item[]
    properties = Dict{Symbol, String}()

    state = iterate(str, i)
    if !isnothing(state)
        while true
            ws, j = tryparsenext(IndentToken, str, i, len)
            ws.hasvalue || break#return Nullable{Item}(), i

            indent, lines = ws.value

            lines >= 1 || return Nullable{Item}(), i

            indent <= item.indent && break
            i = j

            prop, j = tryparsenext(PropertyToken.instance, str, i, len)
            if prop.hasvalue
                i = j
                push!(properties, prop.value)
                continue
            end

            inc, j = tryparsenext(IncludeToken, str, i, len)
            if inc.hasvalue
                i = j
                if pwd.hasvalue
                    file = joinpath(pwd.value, string(str, inc.value))
                    subroot = readfromstring(read(file, String), pwd.value)
                    push!(children, subroot)
                else
                    @warn begin
                        line, pos = findlineindex(str, i)
                        file = string(str, inc.value)
                        "include statement at $line:$pos for target $file skipped (no valid pwd)"
                    end
                end
                continue
            end

            result, i = tryparsenext(ItemToken(indent, pwd), str, i, len)
            result.hasvalue || return Nullable{Item}(), i

            push!(children, result.value)
        end
    end

    result = Item(name, normalize(count), words, properties, children)
    @debug begin
        line, pos = findlineindex(str, i) 
        "$item ends at $line:$pos matching $result"
    end
    return Nullable(result), i
end

function readfromstring(str, pwd=nothing)
    function throw_parse_error(pos)
        lines = split(str, '\n')
        line, pos = findlineindex(str, pos)
        error("parse error at $line:$pos\n$(lines[line])\n$(repeat(' ', pos - 1))^")
    end

    len = length(str)

    ws, i = tryparsenext(IndentToken, str, 1, len)
    ws.hasvalue || throw_parse_error(i)

    parser = ItemToken(ws.value[1], isnothing(pwd) ? Nullable{String}() : Nullable(pwd))
    root, i = tryparsenext(parser, str, i, len)
    root.hasvalue || throw_parse_error(i)

    return root.value
end
readfromfile(filename) = readfromstring(read(filename, String), dirname(filename))