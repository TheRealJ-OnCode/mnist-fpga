LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.NUMERIC_STD.ALL;
ENTITY requant_tb IS
END ENTITY;

ARCHITECTURE arch OF requant_tb IS
    SIGNAL Z : SIGNED(23 DOWNTO 0);
    SIGNAL H : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');

BEGIN
    uut : ENTITY work.requant
        GENERIC MAP(K => 11)
        PORT MAP(Z => Z, H => H);
    PROCESS
        PROCEDURE check(zin : INTEGER; expected : INTEGER) IS
        BEGIN
            Z <= TO_SIGNED(zin, 24);
            WAIT FOR 10 NS;
            ASSERT TO_INTEGER(H) = EXPECTED
            REPORT "error: zin=" & INTEGER'IMAGE(zin) &
                " expected=" & INTEGER'IMAGE(expected) &
                " code output =" & INTEGER'IMAGE(TO_INTEGER(H))
                SEVERITY ERROR;
        END PROCEDURE;
    BEGIN
        check(-5000, 0);
        check(-1, 0);
        check(2047, 0);
        check(2048, 1);
        check(274371, 133);
        check(524287, 255);
        check(524288, 255);
        check(600000, 255);
        REPORT "TEST ENDED";

        WAIT;
    END PROCESS;
END ARCHITECTURE;