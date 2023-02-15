using TextParse, Nullables


import Base:(==)

import TextParse: AbstractToken, Numeric, StringToken, Quoted
import TextParse: LocalOpts, WrapLocalOpts, StrRange
import TextParse: tryparsenext

import Base: show


export readfromstring, readfromfile