-- W[J][I] =   J*196 + I
-- W2[K][J] = 3136 + K*16 + J
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE std.textio.ALL;

ENTITY weight_rom IS
    GENERIC (
        FILE_NAME : STRING
    );
    PORT (
        addr : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        CLK : IN STD_LOGIC;
        data : OUT signed(7 DOWNTO 0)
    );
END weight_rom;

ARCHITECTURE arch OF weight_rom IS
    TYPE rom_t IS ARRAY(0 TO 3295) OF signed (7 DOWNTO 0);
    IMPURE FUNCTION init_rom(fname : STRING) RETURN rom_t IS
        FILE f : text OPEN read_mode IS fname;
        VARIABLE l : line;
        VARIABLE val : STD_LOGIC_VECTOR(7 DOWNTO 0);
        VARIABLE result : rom_t := (OTHERS => (OTHERS => '0'));
    BEGIN
        FOR i IN rom_t'RANGE LOOP
            EXIT WHEN endfile(f);
            readline(f, l);
            read (l, val);
            result(i) := signed(val);
        END LOOP;
        RETURN result;
    END FUNCTION init_rom;
    SIGNAL rom : rom_t := init_rom(FILE_NAME);
BEGIN
    read_proc : PROCESS (CLK)
    BEGIN
        IF (rising_edge(CLK)) THEN
            data <= (rom(to_integer(unsigned(addr))));
        END IF;
    END PROCESS read_proc;

END ARCHITECTURE arch;