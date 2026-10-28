LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY mac IS
    PORT (
        CLK : IN STD_LOGIC;
        PIXEL : IN UNSIGNED(7 DOWNTO 0);
        WEIGHT : IN SIGNED(7 DOWNTO 0);
        BIAS : IN SIGNED(23 DOWNTO 0);
        load : IN STD_LOGIC;
        en : IN STD_LOGIC;
        acc_out : OUT SIGNED(23 DOWNTO 0)
    );
END MAC;

ARCHITECTURE arch OF mac IS
    SIGNAL acc : SIGNED(23 DOWNTO 0);

BEGIN
    PROCESS (CLK)
        VARIABLE T : SIGNED(23 DOWNTO 0);

    BEGIN
        IF (rising_edge(clk)) THEN
            IF (load = '1') THEN
                ACC <= BIAS;
            ELSIF en = '1' THEN
                T := RESIZE((SIGNED('0' & PIXEL) * WEIGHT), 24);
                ACC <= ACC + T;
            END IF;
        END IF;
    END PROCESS;
    acc_out <= acc;

END arch;