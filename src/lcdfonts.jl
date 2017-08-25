module LCDFonts

import Devices
import Devices: push!, render!, GDSMeta, Meta

using ..Rectangles
using ..Points
using ..Cells

using FileIO

using Unitful
import Unitful: μm, nm

export lcdstring!
export characters_demo
export scripted_demo
export referenced_characters_demo

# Horizontal Pixels = 5
# Vertical Pixels = 7 (regular) + 3 (for stems)
const lcd_short = "000000000000000"
const lcd_blank = "00000000000000000000000000000000000"*lcd_short
const lcd_filled  = "11111111111111111111111111111111111111111111111111"
const lcd = Dict{String, String}(
"A" => "01110100011000110001111111000110001"*lcd_short,
"B" => "11110100011000111110100011000111110"*lcd_short,
"C" => "01110100011000010000100001000101110"*lcd_short,
"D" => "11100100101000110001100011001011100"*lcd_short,
"E" => "11111100001000011110100001000011111"*lcd_short,
"F" => "11111100001000011110100001000010000"*lcd_short,
"G" => "01110100011000010111100011000101111"*lcd_short,
"H" => "10001100011000111111100011000110001"*lcd_short,
"I" => "01110001000010000100001000010001110"*lcd_short,
"J" => "00111000100001000010000101001001100"*lcd_short,
"K" => "10001100101010011000101001001010001"*lcd_short,
"L" => "10000100001000010000100001000011111"*lcd_short,
"M" => "10001110111010110101100011000110001"*lcd_short,
"N" => "10001100011100110101100111000110001"*lcd_short,
"O" => "01110100011000110001100011000101110"*lcd_short,
"P" => "11110100011000111110100001000010000"*lcd_short,
"Q" => "01110100011000110001101011001001101"*lcd_short,
"R" => "11110100011000111110101001001010001"*lcd_short,
"S" => "01111100001000001110000010000111110"*lcd_short,
"T" => "11111001000010000100001000010000100"*lcd_short,
"U" => "10001100011000110001100011000101110"*lcd_short,
"V" => "10001100011000110001100010101000100"*lcd_short,
"W" => "10001100011000110101101011010101010"*lcd_short,
"X" => "10001100010101000100010101000110001"*lcd_short,
"Y" => "10001100011000101010001000010000100"*lcd_short,
"Z" => "11111000010001000100010001000011111"*lcd_short,
"a" => "00000000000111000001011111000101111"*lcd_short,
"b" => "10000100001011011001100011000111110"*lcd_short,
"c" => "00000000000111010000100001000101110"*lcd_short,
"d" => "00001000010110110011100011000101111"*lcd_short,
"e" => "00000000000111010001111111000001110"*lcd_short,
"f" => "00110010010100011100010000100001000"*lcd_short,
"g" => "00000000000111110001100011000101111"*"000010000101110",
"h" => "10000100001011011001100011000110001"*lcd_short,
"i" => "00100000000110000100001000010001110"*lcd_short,
"j" => "00010000000011000010000101001001100"*lcd_short,
"k" => "10000100001001010100110001010010010"*lcd_short,
"l" => "01100001000010000100001000010001110"*lcd_short,
"m" => "00000000001101010101101011000110001"*lcd_short,
"n" => "00000000001011011001100011000110001"*lcd_short,
"o" => "00000000000111010001100011000101110"*lcd_short,
"p" => "00000000001011011001100011000111110"*"100001000010000",
"q" => "00000000000110110011100011000101111"*"000010000100001",
"r" => "00000000001011011001100001000010000"*lcd_short,
"s" => "00000000000111010000011100000111110"*lcd_short,
"t" => "01000010001110001000010000100100110"*lcd_short,
"u" => "00000000001000110001100011001101101"*lcd_short,
"v" => "00000000001000110001100010101000100"*lcd_short,
"w" => "00000000001000110001101011010101010"*lcd_short,
"x" => "00000000001000101010001000101010001"*lcd_short,
"y" => "00000000001000110001100011000101111"*"000010000101110",
"z" => "00000000001111100010001000100011111"*lcd_short,
"0" => "01110100011001110101110011000101110"*lcd_short,
"1" => "00100011000010000100001000010001110"*lcd_short,
"2" => "01110100010000100010001000100011111"*lcd_short,
"3" => "11111000100010000010000011000101110"*lcd_short,
"4" => "00010001100101010010111110001000010"*lcd_short,
"5" => "11111100001111000001000011000101110"*lcd_short,
"6" => "00110010001000011110100011000101110"*lcd_short,
"7" => "11111000010001000100010000100001000"*lcd_short,
"8" => "01110100011000101110100011000101110"*lcd_short,
"9" => "01110100011000101111000010001001100"*lcd_short,
"!" => "00100001000010000100000000000000100"*lcd_short,
"@" => "01110100010000101101101011010101110"*lcd_short,
"#" => "01010010101111101010111110101001010"*lcd_short,
"\$" => "00100011111010001110001011111000100"*lcd_short,
"%" => "11000110010001000100010001001100011"*lcd_short,
"^" => "00100010101000100000000000000000000"*lcd_short,
"&" => "01100100101010001000101011001001101"*lcd_short,
"*" => "00000001001010101110101010010000000"*lcd_short,
"(" => "00010001000100001000010000010000010"*lcd_short,
")" => "01000001000001000010000100010001000"*lcd_short,
"-" => "00000000000000011111000000000000000"*lcd_short,
"=" => "00000000001111100000111110000000000"*lcd_short,
"\_" => "00000000000000000000000000000011111"*lcd_short,
"+" => "00000001000010011111001000010000000"*lcd_short,
"{" => "00010001000010001000001000010000010"*lcd_short,
"}" => "01000001000010000010001000010001000"*lcd_short,
"[" => "01110010000100001000010000100001110"*lcd_short,
"]" => "01110000100001000010000100001001110"*lcd_short,
"\\" => "00000100000100000100000100000100000"*lcd_short,
"|" => "00100001000010000100001000010000100"*lcd_short,
":" => "00000011000110000000011000110000000"*lcd_short,
";" => "00000011000110000000011000110000100"*"010000000000000",
"/" => "00000000010001000100010001000000000"*lcd_short,
"\"" => "01010010100101000000000000000000000"*lcd_short,
"'" => "01100001000100000000000000000000000"*lcd_short,
"`" =>"01000001000001000000000000000000000"*lcd_short,
"~" =>"00000000000100010101000100000000000"*lcd_short,
"≈" =>"00000010001010100010010001010100010"*lcd_short,
"." => "00000000000000000000000000110001100"*lcd_short,
"," => "00000000000000000000000000110001100"*"001000100000000",
"?" => "01110100010000100010001000000000100"*lcd_short,
"<" => "00010001000100010000010000010000010"*lcd_short,
">" => "01000001000001000001000100010001000"*lcd_short,
"÷" => "00000001000000011111000000010000000"*lcd_short,
"√" => "00111001000010000100001001010001000"*lcd_short,
"°" => "11100101001110000000000000000000000"*lcd_short,
"α" => "00000000000100110101100101001001101"*lcd_short,
"β" => "00000000000111010001111101000111110"*"100001000010000",
"ϵ" => "00000000000111010000011001000101110"*lcd_short,
"μ" => "00000000001000110001100011001111101"*"100001000010000",
"σ" => "00000000000111110100100101000101110"*lcd_short,
"ρ" => "00000000000011001001100011000111110"*"100001000010000",
"θ" => "00000011101000111111100011000101110"*lcd_short,
"Ω" => "00000000000111010001100010101011011"*lcd_short,
"Σ" => "11111100000100000100010001000011111"*lcd_short,
"π" => "00000000001111101010010100101010011"*lcd_short,
"ħ" => "01000111100100001010011010100101001"*lcd_short,
"∞" => "00000000000101110101110100000000000"*lcd_short,
"γ" => "10001010010101000100001000011000110"*lcd_short,
"δ" => "00111010000010000110010010100100110"*lcd_short,
"Ξ" => "11111100010000001110000001000111111"*lcd_short,
"Γ" => "11111100011000110000100001000010000"*lcd_short,
"ϕ" => "00000101101010110101011100010000100"*lcd_short,
"ω" => "00000000000101010001101011010101010"*lcd_short,
"Π" => "11111010100101001010010100101001010"*lcd_short,
"χ" => "00000000001100101010001000101010011"*lcd_short,
"Δ" => "00000001000101001010100011000111111"*lcd_short,
"Δ" => "00000001000101001010100011000111111"*lcd_short,
"κ" => "00000100010101001100011000101010001"*lcd_short,
"□" => "00000111111000110001100011111100000"*lcd_short,
"ν" => "00000000001000110010101000110001000"*lcd_short,
"η" => "00000000001011011001100011000110001"*"000010000100001",
"░" => "10101010101010101010101010101010101"*"010101010101010",
"█" => lcd_filled,
"λ" => "11000001000010000100001000101010001"*lcd_short,
"τ" => "00000000001111100100001000010000011"*lcd_short,
"ψ" => "00000001001010110101011100010000100"*lcd_short,
"Ψ" => "10101101011010101110001000010001110"*lcd_short,
"Λ" => "00100001000101001010010101000111011"*lcd_short,
"Θ" => "01110100011000110101100011000101110"*lcd_short,
"Φ" => "11111001000111010101011100010011111"*lcd_short,
"†" => "00000001000111000100001000010000000"*lcd_short,
"∠" => "00000000000000100010001000100011111"*lcd_short,
"⟂" => "00000000000010000100001000010011111"*lcd_short,
"≡" => "00000111110000011111000001111100000"*lcd_short,
"±" => "00100001001111100100001000000011111"*lcd_short,
"∓" => "11111000000010000100111110010000100"*lcd_short,
"∇" => "00000111111000110001010100101000100"*lcd_short,
"∂" => "00110000010000101101100011000101110"*lcd_short,
"≠" => "00001000101111100100111110100010000"*lcd_short,
"𝚤" => "00100000000110000100001000010100110"*lcd_short,
" " => lcd_blank
)
const scripted_equation = "H=ħωσ_x+Jσ_y

c^2=a^2+b^2

|Ψ>=a^†a|ψ_1>+b^†b|ψ_2>

e^{𝚤π}=-1 and c_{vac}≈3x10^8 m/s"
const test_string = string(
"Keyboard characters:

ABCDEFGHIJKLMNOPQRSTUVWXYZ
abcdefghijklmnopqrstuvwxyz

~!@#\$%^&*()\_+
`1234567890-=

[]\\{}|;':\",./<>?

Non-keyboard characters:

αβγδϵηθκλμνπρστϕχψωħ
ΩΣΞΓΠΨΔΛΘΦ
𝚤∞÷√±∓≠≡≈⟂∠°∂∇†□░█\n\n",
length(lcd), " characters supported so far.

Line limit demonstration (newline character not present):
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam in enim vestibulum, laoreet ligula at, convallis nisl. Curabitur elit mi, luctus a semper sed, euismod sed turpis. Nunc ac arcu egestas, tristique leo vitae, pellentesque augue. Vivamus massa urna, varius quis scelerisque ac, imperdiet non magna. Curabitur id rhoncus nisl. Cras consequat vulputate mauris, sit amet congue odio. Sed posuere ullamcorper libero, id efficitur diam auctor quis. Morbi ac neque lectus. Maecenas ultrices placerat justo, id sollicitudin velit dapibus laoreet. Mauris sodales consectetur mi eget suscipit. Morbi eu rutrum turpis. In sed dolor eu purus venenatis feugiat. Maecenas lacinia dui vel consequat venenatis. Aenean viverra, quam nec tempus iaculis, velit libero laoreet ligula, id hendrerit velit lorem at velit.")
reference_test_string = "aaaa
bbbb
cccc
dddd
eeee
ffff
gggg
♇♇♇♇" # End with invalid character to test catch fallback

"""
    lcdstring!(string_cell::Cell, str::String, pixelsize, pixelspacing; scripting = false, linelimit = 2^32, meta::Meta=GDSMeta(0,0))
Renders the string `str` to cell `c` in a pixelated font format.
- `pixelsize`: dimension for the width/height of each pixel
- `pixelspacing`: dimension for the spacing between adjacent pixels
- `scripting`: boolean parameter for allocating special characters `^`, `_`, `{`, and `}` for superscripting and subscripting. Follows the same usage as LaTex.
- `linelimit`: sets the maximum number of characters per line and continues on a new line if `str` is longer than `linelimit`
- `verbose`: prints out information about the character dictionary
"""
function lcdstring!(string_cell::Cell, str::String, pixelsize, pixelspacing; meta::Meta=GDSMeta(0,0), scripting = false, linelimit = 2^32, verbose = false)
    hpos = 1
    vpos = 1
    subscript = -1
    superscript = +1
    waitforend = false
    existing_chars = Dict{String, Devices.Cells.CellReference{}}()
    for s in str
        if subscript == 0
            offset = -0.3
        elseif superscript == 0
            offset = +0.3
        else
            offset = 0.0
        end
        if s == '\n' || hpos > linelimit
            vpos += 1
            hpos = 1
        elseif s == '_' && scripting
            subscript = +1
        elseif s == '^' && scripting
            superscript = -1
        elseif s == '{' && scripting
            waitforend = true
        elseif s == '}' && scripting
            subscript = -1
            superscript = +1
            waitforend = false
        else
            s = string(s)
            cr = get(existing_chars, s, 0)
            if  cr == 0
                verbose? println("Character \"", s, "\" not found. Adding to CellReference dictionary."):nothing
                ss = get(lcd, s, s)
                try
                    s_cell = (typeof(string_cell))(uniquename("lcd"))
                    drawlcdcell!(s_cell, ss, pixelsize, pixelspacing, meta)
                    crs = CellReference(s_cell, Point(0*pixelspacing, 0*pixelspacing))
                    push!(string_cell.refs, crs + Point(pixelspacing*6*(hpos - 1), -11*pixelspacing*(vpos - offset)))
                    existing_chars[s] = crs
                catch
                    warn("Cannot render \"", s, "\" character. Replacing with a blank character.")
                    blank_catch = get(existing_chars, " ", 0)
                    if  blank_catch == 0
                        verbose? println("Blank character not in dictionary. Adding to it now."):nothing
                        s_cell = (typeof(string_cell))(uniquename("lcd"))
                        drawlcdcell!(s_cell, lcd_blank, pixelsize, pixelspacing, meta)
                        crs = CellReference(s_cell, Point(0*pixelspacing, 0*pixelspacing))
                        push!(string_cell.refs, crs + Point(pixelspacing*6*(hpos - 1), -11*pixelspacing*(vpos - offset)))
                        existing_chars[" "] = crs
                    else
                        push!(string_cell.refs, blank_catch + Point(pixelspacing*6*(hpos - 1), -11*pixelspacing*(vpos - offset)))
                    end
                end
            else
                verbose? println("Character \"", s, "\" already in dictionary."):nothing
                push!(string_cell.refs, cr + Point(pixelspacing*6*(hpos - 1), -11*pixelspacing*(vpos - offset)))
            end
            hpos += 1
        end
        if !waitforend
            subscript -= 1
            superscript += 1
        end
    end
    string_cell
end

"""
    drawlcdcell!(c::Cell, code::String, pixelsize, pixelspacing, meta::Meta)
Renders pixels from the codeword `code` onto a 5x10 (horizontal x vertical) grid in cell `c`.
- `pixelsize`: dimension for the width/height of each pixel
- `pixelspacing`: dimension for the spacing between adjacent pixels
"""
function drawlcdcell!(c::Cell, code::String, pixelsize, pixelspacing, meta::Meta)
    r = Rectangle(pixelsize, pixelsize) + (pixelspacing - pixelsize)/2*Point(1,1)
    idx = 1
    for row in 1:10
        for col in 1:5
            if code[idx] == '1'
                render!(c, r + Point(pixelspacing*(col - 1), pixelspacing*(10 - row)), Rectangles.Plain(), meta)
            end
            idx+=1
        end
    end
    c
end
"""
    scripted_demo(save_path = joinpath(homedir(),"Desktop"))
Demo script for demonstrating the use of the `scripting` parameter in `lcdstring!()`.
"""
function scripted_demo(save_path = joinpath(homedir(),"Desktop"))
    cd(save_path)
    c = Cell("scripted", nm)
    save("scripted.gds", lcdstring!(c, scripted_equation, 1μm, 1.25μm, scripting = true))
end

"""
    characters_demo(save_path = joinpath(homedir(),"Desktop"))
Demo script for demonstrating the avalible characters in `lcdstring!()` and the `linelimit` parameter in use.
"""
function characters_demo(save_path = joinpath(homedir(),"Desktop"))
    cd(save_path)
    c = Cell("characters", nm)
    save("characters.gds", lcdstring!(c, test_string, 1μm, 1.25μm, linelimit = 80))
end

"""
    characters_demo(save_path = joinpath(homedir(),"Desktop"))
Demo script for demonstrating the memory saving ability of keeping CellReferences for previously used characters in `lcdstring!()`.
"""
function referenced_characters_demo(save_path = joinpath(homedir(),"Desktop"))
    cd(save_path)
    c = Cell("referenced_characters", nm)
    save("referenced_characters.gds", lcdstring!(c, reference_test_string, 1μm, 1.25μm, verbose = true))
end

end
