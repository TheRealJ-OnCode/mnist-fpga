LIBRARY ieee;
LIBRARY std;
USE std.textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY BIAS_ROM IS
    GENERIC (
        file_name : STRING := "../python/biases.txt"
    );
    PORT (
        ADDR : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
        CLK : IN STD_LOGIC;
        data : OUT SIGNED(23 DOWNTO 0)
    );
END;

ARCHITECTURE ARCH OF BIAS_ROM IS
    TYPE rom_t IS ARRAY (0 TO 25) OF SIGNED(23 DOWNTO 0);
    IMPURE FUNCTION init_bias(fname : STRING) RETURN rom_t IS
        FILE f : text OPEN READ_MODE IS fname;
        VARIABLE L : line;
        VARIABLE VAL : STD_LOGIC_VECTOR(23 DOWNTO 0);
        VARIABLE RESULT : rom_t := (OTHERS => (OTHERS => '0'));
    BEGIN
        FOR J IN rom_t'RANGE LOOP
            EXIT WHEN ENDFILE(F);
            readline(F, L);
            -- REPORT(LF & "Satir : " & INTEGER'image(j) & " => " & L.ALL);
            read(L, VAL);
            -- REPORT(LF & "VALUE : " & INTEGER'image(to_integer(signed(val))));
            RESULT(J) := signed(VAL);
            -- REPORT LF & "RESULT(" & INTEGER'image(J) & ") = " & INTEGER'IMAGE(TO_INTEGER(RESULT(J)));
            -- REPORT("________________________________");
        END LOOP;
        RETURN result;
    END FUNCTION init_bias;
    SIGNAL bias : rom_t := init_bias(file_name);
BEGIN
    PROCESS (clk)
    BEGIN
        IF (RISING_EDGE(CLK)) THEN
            DATA <= bias(to_integer(unsigned(addr)));
        END IF;
    END PROCESS;
END ARCHITECTURE ARCH;