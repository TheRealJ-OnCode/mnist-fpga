LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY argmax_tb IS
END argmax_tb;

ARCHITECTURE arch OF argmax_tb IS
    SIGNAL CLK : STD_LOGIC := '0';
    SIGNAL CLEAR : STD_LOGIC := '0';
    SIGNAL EN : STD_LOGIC := '0';
    SIGNAL SCORE : SIGNED(23 DOWNTO 0) := (OTHERS => '0');
    SIGNAL idx : UNSIGNED(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL digit : UNSIGNED(3 DOWNTO 0);
    SIGNAL done : BOOLEAN := false;
BEGIN
    -- 10 ns periyotlu saat, test bitince durur
    clk <= NOT clk AFTER 5 ns WHEN NOT done;

    uut : ENTITY work.argmax
        PORT MAP(CLK => clk, CLEAR => clear, EN => en, SCORE => score, idx => idx, digit => digit);

    stim : PROCESS
        -- bir adim: girisleri ver, kenari bekle, digit'i kontrol et
        PROCEDURE step(c, e : STD_LOGIC; s, i : INTEGER; expected : INTEGER) IS
        BEGIN
            clear <= c;
            en <= e;
            score <= TO_SIGNED(s, 24);
            idx <= TO_UNSIGNED(i, 4);
            WAIT UNTIL rising_edge(clk);
            WAIT FOR 1 ns;
            ASSERT TO_INTEGER(digit) = expected
            REPORT "HATA: score=" & INTEGER'IMAGE(s) &
                " idx=" & INTEGER'IMAGE(i) &
                " beklenen=" & INTEGER'IMAGE(expected) &
                " okunan=" & INTEGER'IMAGE(TO_INTEGER(digit))
                SEVERITY error;
        END PROCEDURE;
    BEGIN
        -- A) kagittaki ornek: rakam 2 ve 6 esit (230), cevap 2 olmali
        step('1', '0', 0, 0, 0); -- clear
        step('0', '1', -40, 0, 0);
        step('0', '1', 15, 1, 1);
        step('0', '1', 230, 2, 2);
        step('0', '1', -12, 3, 2);
        step('0', '1', 60, 4, 2);
        step('0', '1', -5, 5, 2);
        step('0', '1', 230, 6, 2); -- esitlik: 2 kalmali
        step('0', '1', 110, 7, 2);
        step('0', '1', 35, 8, 2);
        step('0', '1', -8, 9, 2);
        REPORT "A bitti: digit = " & INTEGER'IMAGE(TO_INTEGER(digit));

        -- B) en = 0 iken buyuk puan gelirse degismemeli
        step('0', '0', 99999, 7, 2);
        REPORT "B bitti: digit = " & INTEGER'IMAGE(TO_INTEGER(digit));

        -- C) hepsi negatif: en buyuk -300 (rakam 1 ve 6), cevap 1 olmali
        step('1', '0', 0, 0, 0); -- clear
        step('0', '1', -500, 0, 0);
        step('0', '1', -300, 1, 1);
        step('0', '1', -900, 2, 1);
        step('0', '1', -301, 3, 1);
        step('0', '1', -450, 4, 1);
        step('0', '1', -1000, 5, 1);
        step('0', '1', -300, 6, 1); -- esitlik: 1 kalmali
        step('0', '1', -800, 7, 1);
        step('0', '1', -700, 8, 1);
        step('0', '1', -600, 9, 1);
        REPORT "C bitti: digit = " & INTEGER'IMAGE(TO_INTEGER(digit));

        -- D) clear ve en ayni anda: clear kazanmali
        step('1', '1', 99999, 5, 0);
        REPORT "D bitti: digit = " & INTEGER'IMAGE(TO_INTEGER(digit));

        REPORT "TEST BITTI";
        done <= true;
        WAIT;
    END PROCESS;
END arch;