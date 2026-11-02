LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY ARGMAX IS
    PORT (
        CLK : IN STD_LOGIC;
        CLEAR : IN STD_LOGIC;
        EN : IN STD_LOGIC;
        SCORE : IN SIGNED(23 DOWNTO 0);
        idx : IN unsigned(3 DOWNTO 0);
        digit : OUT UNSIGNED(3 DOWNTO 0)
    );
END ARGMAX;

ARCHITECTURE arch OF ARGMAX IS
    SIGNAL best_r : SIGNED(23 DOWNTO 0) := to_signed( - (2 ** 23), 24);
    SIGNAL best_idx_r : UNSIGNED(3 DOWNTO 0) := (OTHERS => '0');
BEGIN
    PROCESS (CLK)
    BEGIN
        IF (rising_edge(clk)) THEN
            IF (clear = '1') THEN
                best_r <= TO_SIGNED( - (2 ** 23), 24);
                best_idx_r <= (OTHERS => '0');
            ELSIF en = '1' AND SCORE > best_r THEN
                best_r <= score;
                best_idx_r <= idx;
            END IF;
        END IF;
    END PROCESS;
    digit <= best_idx_r;

END arch;