@testset verbose=true "Parser" begin
    let text = """
        [root]
            A: 1
            B: 2
            [sub]
                [f1.txt]
                    Val (a, b)
                [f2.txt]
                    Size: 10
                    new Val
                    4 Points
            [f3.txt]
                xs (x)
            <inc.meta>
""", targetA = Item("root", 1, [], Dict(:A => "1", :B => "2"), [
    Item("sub", 1, [], Dict(), [
        Item("f1.txt", 1, [], Dict(), [
            Item(:Val, 1, [:a, :b], Dict(), [])
        ]),
        Item("f2.txt", 1, [], Dict(:Size => "10"), [
            Item(:Val, 1, [:new], Dict(), []),
            Item(:Points, 4, [], Dict(), [])
        ])
    ]),
    Item("f3.txt", 1, [], Dict(), [
        Item(:xs, 1, [:x], Dict(), [])
    ])
]), targetB = Item(".", 1, [], Dict(), [
    Item(:Test, 1, [:include], Dict(), []),
    Item("meta", 1, [], Dict(), [
        Item(".", 1, [], Dict(:value => "in include"), [])
    ])
])
        root = @test_logs (:warn, r"include statement at \d+:\d+ for target inc.meta skipped \(no valid pwd\)") readfromstring(text)
        @test root == targetA

        root = readfromfile(joinpath(@__DIR__, "test.meta"))
        @test root == targetB
    end
end