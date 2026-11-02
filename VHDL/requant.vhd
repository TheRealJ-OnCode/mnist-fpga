LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY requant IS
    GENERIC (
        K : INTEGER := 11
    );
    PORT (
        Z : IN SIGNED(23 DOWNTO 0);
        H : OUT UNSIGNED(7 DOWNTO 0)
    );
END;

ARCHITECTURE arch OF requant IS
BEGIN
    PROCESS (ALL)
        VARIABLE v : signed(23 DOWNTO 0);

    BEGIN
        IF (Z < 0) THEN
            v := (OTHERS => '0');
        ELSE
            V := Z;
        END IF;
        V:=SHIFT_RIGHT(v,K);
        IF(V>255) THEN
            h<=(OTHERS=>'1');
        ELSE 
            H <= UNSIGNED(V(7 DOWNTO 0 ));
        END IF ;

    END PROCESS;
END ;