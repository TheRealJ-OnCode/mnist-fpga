-- weight_rom testbench
-- Bilinen 5 adresi okur, Python'daki degerlerle karsilastirir.
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY weight_rom_tb IS
END weight_rom_tb;

ARCHITECTURE sim OF weight_rom_tb IS
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL addr : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '0');
    SIGNAL data : signed(7 DOWNTO 0);
    SIGNAL done : BOOLEAN := false;
BEGIN
    -- 10 ns periyotlu saat, test bitince durur
    clk <= NOT clk AFTER 5 ns WHEN NOT done;

    uut : ENTITY work.weight_rom
        GENERIC MAP(FILE_NAME => "../python/weights.txt")
        PORT MAP(addr => addr, CLK => clk, data => data);

    stim : PROCESS
        -- bir adresi oku ve beklenen degerle karsilastir
        PROCEDURE check(a : INTEGER; expected : INTEGER) IS
        BEGIN
            addr <= STD_LOGIC_VECTOR(to_unsigned(a, 12));
            WAIT UNTIL rising_edge(clk); -- senkron ROM: 1 darbe sonra veri gelir
            WAIT FOR 1 ns; -- cikis otursun
            ASSERT to_integer(data) = expected
            REPORT "HATA adres " & INTEGER'image(a) &
                ": beklenen " & INTEGER'image(expected) &
                ", okunan " & INTEGER'image(to_integer(data))
                SEVERITY error;
            REPORT "adres " & INTEGER'image(a) & " -> " & INTEGER'image(to_integer(data));
        END PROCEDURE;
    BEGIN
        check(0, 0); -- W1[0][0]
        check(1, 4); -- W1[0][1]
        check(2, -7); -- W1[0][2]  (isaret testi)
        check(397, -1); -- W1[2][5]  = 2*196 + 5
        check(3191, -21); -- W2[3][7]  = 3136 + 3*16 + 7

        REPORT "TEST BITTI";
        done <= true;
        WAIT;
    END PROCESS;
END sim;