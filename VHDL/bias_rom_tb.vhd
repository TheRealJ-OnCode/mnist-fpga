LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY BIAS_ROM_TB IS
END;
ARCHITECTURE sim OF BIAS_ROM_TB IS
    SIGNAL CLK : STD_LOGIC := '0';
    SIGNAL ADDR : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');
    SIGNAL DATA : SIGNED(23 DOWNTO 0);
    SIGNAL DONE : BOOLEAN := FALSE;
BEGIN
    clk <= NOT clk AFTER 5 ns WHEN NOT DONE;

    uut : ENTITY work.bias_rom
        GENERIC MAP(FILE_NAME => "../python/biases.txt")
        PORT MAP(ADDR => ADDR, CLK => CLK, DATA => DATA);
    stim : PROCESS
        PROCEDURE check(address : INTEGER; expected : INTEGER)IS
        BEGIN
            addr <= STD_LOGIC_VECTOR (TO_UNSIGNED(address, 5));
            WAIT UNTIL rising_edge(clk);
            WAIT FOR 1 ns;
            ASSERT to_integer(data) = expected
            REPORT "ERR ADDR " & INTEGER'image(address) &
                ": EXPCTD " & INTEGER'image(expected) &
                ", READED " & INTEGER'image(to_integer(data))
                SEVERITY error;
            REPORT "ADDR " & INTEGER'image(address) & " -> " & INTEGER'image(to_integer(data));

        END PROCEDURE;
    BEGIN
        check(0, 5947); -- b1[0]
        check(5, 24079); -- b1[5]
        check(13, -12473); -- b1[13]  
        check(16, -97); -- b2[0]  
        check(25, -81); -- b2[9]  
        REPORT("FAAAAAAAAAAAAA => TEST ENDED");
        done <= true;
        WAIT;

    END PROCESS;
END sim;