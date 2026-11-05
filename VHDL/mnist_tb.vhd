LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;

ENTITY mnist_tb IS
    GENERIC (
        N_IMG : INTEGER := 500
    );
END mnist_tb;

ARCHITECTURE sim OF mnist_tb IS
    TYPE pix_t IS ARRAY (0 TO 500 * 196 - 1) OF UNSIGNED(7 DOWNTO 0);
    TYPE exp_t IS ARRAY (0 TO 499) OF INTEGER;

    IMPURE FUNCTION load_pixels(fname : STRING) RETURN pix_t IS
        FILE f     : text OPEN read_mode IS fname;
        VARIABLE l : line;
        VARIABLE v : STD_LOGIC_VECTOR(7 DOWNTO 0);
        VARIABLE r : pix_t;
    BEGIN
        FOR i IN pix_t'RANGE LOOP
            readline(f, l);
            read(l, v);
            r(i) := UNSIGNED(v);
        END LOOP;
        RETURN r;
    END FUNCTION;

    IMPURE FUNCTION load_expected(fname : STRING) RETURN exp_t IS
        FILE f     : text OPEN read_mode IS fname;
        VARIABLE l : line;
        VARIABLE v : STD_LOGIC_VECTOR(3 DOWNTO 0);
        VARIABLE r : exp_t;
    BEGIN
        FOR i IN exp_t'RANGE LOOP
            readline(f, l);
            read(l, v);
            r(i) := TO_INTEGER(UNSIGNED(v));
        END LOOP;
        RETURN r;
    END FUNCTION;

    CONSTANT PIX : pix_t := load_pixels("../python/images.txt");
    CONSTANT EXP : exp_t := load_expected("../python/expected.txt");

    TYPE h1_ref_t IS ARRAY (0 TO 15) OF INTEGER;
    CONSTANT H1_REF : h1_ref_t := (50, 0, 0, 0, 11, 49, 0, 0, 29, 29, 11, 13, 0, 10, 29, 37);

    SIGNAL clk      : STD_LOGIC := '0';
    SIGNAL rst      : STD_LOGIC := '1';
    SIGNAL img_we   : STD_LOGIC := '0';
    SIGNAL img_addr : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL img_data : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL start    : STD_LOGIC := '0';
    SIGNAL done     : STD_LOGIC;
    SIGNAL digit    : UNSIGNED(3 DOWNTO 0);

    SIGNAL dbg_h_we  : STD_LOGIC;
    SIGNAL dbg_h_idx : UNSIGNED(3 DOWNTO 0);
    SIGNAL dbg_h_val : UNSIGNED(7 DOWNTO 0);

    SIGNAL img_no   : INTEGER := 0;      
    SIGNAL finished : BOOLEAN := false;
BEGIN
    clk <= NOT clk AFTER 5 ns WHEN NOT finished;

    uut : ENTITY work.mnist_core
        PORT MAP (clk => clk, rst => rst,
                  img_we => img_we, img_addr => img_addr, img_data => img_data,
                  start => start, done => done, digit => digit,
                  dbg_h_we => dbg_h_we, dbg_h_idx => dbg_h_idx, dbg_h_val => dbg_h_val);

    h1_check : PROCESS (clk)
        VARIABLE j : INTEGER;
    BEGIN
        IF rising_edge(clk) THEN
            IF dbg_h_we = '1' AND img_no = 0 THEN
                j := TO_INTEGER(dbg_h_idx);
                REPORT "resim 0, h1_q(" & INTEGER'IMAGE(j) & ") = " &
                       INTEGER'IMAGE(TO_INTEGER(dbg_h_val)) &
                       "   (Python: " & INTEGER'IMAGE(H1_REF(j)) & ")";
                ASSERT TO_INTEGER(dbg_h_val) = H1_REF(j)
                    REPORT "HATA: h1_q(" & INTEGER'IMAGE(j) & ") Python ile ayni degil"
                    SEVERITY error;
            END IF;
        END IF;
    END PROCESS;

    stim : PROCESS
        VARIABLE match : INTEGER := 0;
    BEGIN
        WAIT UNTIL rising_edge(clk);
        WAIT UNTIL rising_edge(clk);
        rst <= '0';

        FOR n IN 0 TO N_IMG - 1 LOOP
            img_no <= n;

            FOR i IN 0 TO 195 LOOP
                img_we   <= '1';
                img_addr <= TO_UNSIGNED(i, 8);
                img_data <= PIX(n * 196 + i);
                WAIT UNTIL rising_edge(clk);
            END LOOP;
            img_we <= '0';

            start <= '1';
            WAIT UNTIL rising_edge(clk);
            start <= '0';
            WAIT UNTIL rising_edge(clk) AND done = '1';
            WAIT FOR 1 ns;

            IF TO_INTEGER(digit) = EXP(n) THEN
                match := match + 1;
            ELSE
                REPORT "HATA: resim " & INTEGER'IMAGE(n) &
                       " devre=" & INTEGER'IMAGE(TO_INTEGER(digit)) &
                       " beklenen=" & INTEGER'IMAGE(EXP(n))
                    SEVERITY error;
            END IF;

            IF n = 0 THEN
                REPORT "resim 0: devre = " & INTEGER'IMAGE(TO_INTEGER(digit)) &
                       ", beklenen = " & INTEGER'IMAGE(EXP(0));
            END IF;
        END LOOP;

        REPORT "SONUC: " & INTEGER'IMAGE(match) & " / " & INTEGER'IMAGE(N_IMG) & " eslesme";
        finished <= true;
        WAIT;
    END PROCESS;
END sim;