-- neuron0_tb: ilk resmin ilk noronunu ELLE hesaplatir.
-- FSM'in yapacagi isi burada process ve for dongusu yapiyor.
-- Python referansi: z = 103898, h1_q = 50
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;

ENTITY neuron0_tb IS
END neuron0_tb;

ARCHITECTURE sim OF neuron0_tb IS
    -- ===== 1. resim: images.txt'nin ilk 196 satiri =====
    TYPE img_t IS ARRAY (0 TO 195) OF UNSIGNED(7 DOWNTO 0);

    IMPURE FUNCTION load_image(fname : STRING) RETURN img_t IS
        FILE f       : text OPEN read_mode IS fname;
        VARIABLE l   : line;
        VARIABLE v   : STD_LOGIC_VECTOR(7 DOWNTO 0);
        VARIABLE img : img_t;
    BEGIN
        FOR i IN img_t'RANGE LOOP
            readline(f, l);
            read(l, v);
            img(i) := UNSIGNED(v);
        END LOOP;
        RETURN img;
    END FUNCTION;

    CONSTANT IMG : img_t := load_image("../python/images.txt");

    -- ===== kablolar =====
    SIGNAL clk    : STD_LOGIC := '0';
    SIGNAL done   : BOOLEAN   := false;

    SIGNAL w_addr : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '0');
    SIGNAL w_data : SIGNED(7 DOWNTO 0);

    SIGNAL b_addr : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');
    SIGNAL b_data : SIGNED(23 DOWNTO 0);

    SIGNAL pixel  : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL load   : STD_LOGIC := '0';
    SIGNAL en     : STD_LOGIC := '0';
    SIGNAL acc    : SIGNED(23 DOWNTO 0);
BEGIN
    clk <= NOT clk AFTER 5 ns WHEN NOT done;

    -- ===== uc modul, birbirine bagli =====
    wrom : ENTITY work.weight_rom
        GENERIC MAP (FILE_NAME => "../python/weights.txt")
        PORT MAP (addr => w_addr, CLK => clk, data => w_data);

    brom : ENTITY work.bias_rom
        GENERIC MAP (FILE_NAME => "../python/biases.txt")
        PORT MAP (ADDR => b_addr, CLK => clk, data => b_data);

    mac0 : ENTITY work.mac
        PORT MAP (CLK => clk, PIXEL => pixel, WEIGHT => w_data,
                BIAS => b_data, load => load, en => en, acc_out => acc);

    -- ===== "elle FSM" =====
    stim : PROCESS
    BEGIN
        -- 1) bias_rom'dan noron 0'in bias'ini oku (senkron: 1 darbe)
        b_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(0, 5));
        WAIT UNTIL rising_edge(clk);
        WAIT FOR 1 ns;
        -- 2) MAC'e bias'i yukle
        load <= '1';
        WAIT UNTIL rising_edge(clk);
        WAIT FOR 1 ns;
        load <= '0';
        REPORT "bias yuklendi: acc = " & INTEGER'IMAGE(TO_INTEGER(acc));
        FOR i IN 0 TO 196 LOOP
            IF i <= 195 THEN
                w_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(i, 12));
            END IF;
            -- piksel: bir ad?m geriden, çünkü a??rl?k bir darbe geç geliyor
            IF i >= 1 THEN
                pixel <= IMG(i - 1);
                en    <= '1';
            ELSE
                en    <= '0';   -- ilk tur: ROM henüz do?ru a??rl??? vermedi
            END IF;
            WAIT UNTIL rising_edge(clk);
            WAIT FOR 1 ns;
        END LOOP;
        en <= '0';
        REPORT "z      = " & INTEGER'IMAGE(TO_INTEGER(acc));
        REPORT "beklenen 103898";
        done <= true;
        WAIT;
    END PROCESS;
END sim;