LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;

ENTITY mac_tb IS
END MAC_tb;

ARCHITECTURE SIM OF MAC_TB IS
    SIGNAL CLK : STD_LOGIC := '0';
    SIGNAL PIXEL : UNSIGNED(7 DOWNTO 0);
    SIGNAL WEIGHT : SIGNED(7 DOWNTO 0);
    SIGNAL bias : signed(23 DOWNTO 0) := to_signed(5, 24);
    SIGNAL load : STD_LOGIC;
    SIGNAL en : STD_LOGIC;
    SIGNAL acc_out : SIGNED(23 DOWNTO 0);
    SIGNAL DONE : BOOLEAN := FALSE;

BEGIN
    CLK <= NOT CLK AFTER 5 NS WHEN NOT DONE;
    uut : ENTITY work.mac
        PORT MAP(clk => clk, PIXEL => pixel, WEIGHT => WEIGHT, bias => bias, load => load, en => en, acc_out => acc_out);
    tester : PROCESS

        PROCEDURE step(l, e : STD_LOGIC;p, w : INTEGER;expected : INTEGER) IS
        BEGIN
            load <= l;
            en <= e;
            WEIGHT <= TO_SIGNED(w, 8);
            PIXEL <= TO_UNSIGNED(p, 8);
            WAIT UNTIL rising_edge(CLK);
            WAIT FOR 1 ns;
            ASSERT TO_INTEGER(ACC_out) = expected
            REPORT "ERR" & INTEGER'IMAGE(TO_INTEGER(ACC_out)) &
                "EXPECTED: " & INTEGER'IMAGE(EXPECTED)
                SEVERITY error;
            REPORT "acc_out = " & INTEGER'IMAGE(TO_INTEGER(acc_out));
        END PROCEDURE;

    BEGIN
        step('1', '0', 0, 0, 5);
        step ('0', '1', 10, 2, 25);
        step('0', '1', 3, -4, 13);
        step('0', '1', 200, -1, -187);
        step('0', '1', 255, -128, -32827);
        step('0', '0', 99, 99, -32827);
        bias <= to_signed(-12473, 24);
        -- step('1', '1', 99, 99, -41414);
        step('1', '1', 99, 99, -12473);

        REPORT("100%=> TEST ENDED");
        done <= true;
        WAIT;
    END PROCESS tester;
END ARCHITECTURE;