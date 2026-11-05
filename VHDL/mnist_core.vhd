
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY mnist_core IS
    GENERIC (
        WEIGHT_FILE : STRING  := "../python/weights.txt";
        BIAS_FILE   : STRING  := "../python/biases.txt";
        K           : INTEGER := 11
    );
    PORT (
        clk      : IN  STD_LOGIC;
        rst      : IN  STD_LOGIC;

        img_we   : IN  STD_LOGIC;
        img_addr : IN  UNSIGNED(7 DOWNTO 0);  
        img_data : IN  UNSIGNED(7 DOWNTO 0);

        start    : IN  STD_LOGIC;
        done     : OUT STD_LOGIC;
        digit    : OUT UNSIGNED(3 DOWNTO 0);

        dbg_h_we  : OUT STD_LOGIC;
        dbg_h_idx : OUT UNSIGNED(3 DOWNTO 0);
        dbg_h_val : OUT UNSIGNED(7 DOWNTO 0)
    );
END mnist_core;

ARCHITECTURE rtl OF mnist_core IS
    TYPE state_t IS (IDLE, BIAS_RD, BIAS_LD, RUN, STORE, DONE_S);
    SIGNAL state  : state_t := IDLE;

    SIGNAL layer2 : STD_LOGIC := '0';                 
    SIGNAL neuron : INTEGER RANGE 0 TO 15 := 0;       
    SIGNAL cnt    : INTEGER RANGE 0 TO 196 := 0;      
    SIGNAL w_ptr  : INTEGER RANGE 0 TO 3295 := 0;    

    SIGNAL n_in   : INTEGER RANGE 0 TO 196;           
    SIGNAL n_last : INTEGER RANGE 0 TO 15;            

    TYPE img_t IS ARRAY (0 TO 195) OF UNSIGNED(7 DOWNTO 0);
    SIGNAL img    : img_t := (OTHERS => (OTHERS => '0'));
    SIGNAL img_q  : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');   

    TYPE h1_t IS ARRAY (0 TO 15) OF UNSIGNED(7 DOWNTO 0);
    SIGNAL h1     : h1_t := (OTHERS => (OTHERS => '0'));
    SIGNAL h_q    : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');  

    SIGNAL w_addr  : STD_LOGIC_VECTOR(11 DOWNTO 0);
    SIGNAL w_data  : SIGNED(7 DOWNTO 0);
    SIGNAL b_addr  : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL b_data  : SIGNED(23 DOWNTO 0);
    SIGNAL pixel   : UNSIGNED(7 DOWNTO 0);
    SIGNAL load    : STD_LOGIC;
    SIGNAL en      : STD_LOGIC;
    SIGNAL acc     : SIGNED(23 DOWNTO 0);
    SIGNAL h_new   : UNSIGNED(7 DOWNTO 0);
    SIGNAL am_clr  : STD_LOGIC;
    SIGNAL am_en   : STD_LOGIC;
    SIGNAL n_idx   : UNSIGNED(3 DOWNTO 0);
BEGIN
-- LAYERE GORE SABITLE
n_in   <= 196 WHEN layer2 = '0' ELSE 16;
    n_last <= 15  WHEN layer2 = '0' ELSE 9;

-- FSM
    fsm : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF rst = '1' THEN
                state  <= IDLE;
                layer2 <= '0';
                neuron <= 0;
                cnt    <= 0;
                w_ptr  <= 0;
            ELSE
                CASE state IS
                    WHEN IDLE | DONE_S =>
                        IF start = '1' THEN
                            layer2 <= '0';
                            neuron <= 0;
                            w_ptr  <= 0;
                            state  <= BIAS_RD;
                        END IF;

                    WHEN BIAS_RD =>
                        state <= BIAS_LD;

                    WHEN BIAS_LD =>
                        cnt   <= 0;
                        state <= RUN;

                    WHEN RUN =>
                        IF cnt < n_in AND w_ptr < 3295 THEN
                            w_ptr <= w_ptr + 1;
                        END IF;
                        IF cnt = n_in THEN
                            state <= STORE;
                        ELSE
                            cnt <= cnt + 1;
                        END IF;

                    WHEN STORE =>
                        IF layer2 = '0' THEN
                            h1(neuron) <= h_new;
                        END IF;

                        IF neuron = n_last THEN
                            IF layer2 = '0' THEN
                                layer2 <= '1';     -- 2. katmana gec
                                neuron <= 0;
                                state  <= BIAS_RD;
                            ELSE
                                state  <= DONE_S;  -- bitti
                            END IF;
                        ELSE
                            neuron <= neuron + 1;
                            state  <= BIAS_RD;
                        END IF;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    img_mem : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF img_we = '1' THEN
                img(TO_INTEGER(img_addr)) <= img_data;
            END IF;
            IF cnt < 196 THEN
                img_q <= img(cnt);
            END IF;
        END IF;
    END PROCESS;

    h1_mem : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF cnt < 16 THEN
                h_q <= h1(cnt);
            END IF;
        END IF;
    END PROCESS;

    load   <= '1' WHEN state = BIAS_LD ELSE '0';
    en     <= '1' WHEN state = RUN AND cnt >= 1 ELSE '0';   -- bir darbe geriden
    am_clr <= '1' WHEN (state = IDLE OR state = DONE_S) AND start = '1' ELSE '0';
    am_en  <= '1' WHEN state = STORE AND layer2 = '1' ELSE '0';
    done   <= '1' WHEN state = DONE_S ELSE '0';

    w_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(w_ptr, 12));
    b_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(neuron, 5)) WHEN layer2 = '0'
              ELSE STD_LOGIC_VECTOR(TO_UNSIGNED(16 + neuron, 5));
    pixel  <= img_q WHEN layer2 = '0' ELSE h_q;

    dbg_h_we  <= '1' WHEN state = STORE AND layer2 = '0' ELSE '0';
    n_idx     <= TO_UNSIGNED(neuron, 4);
    dbg_h_idx <= n_idx;
    dbg_h_val <= h_new;

    -- ===== alt moduller =====
    wrom : ENTITY work.weight_rom
        GENERIC MAP (FILE_NAME => WEIGHT_FILE)
        PORT MAP (addr => w_addr, CLK => clk, data => w_data);

    brom : ENTITY work.bias_rom
        GENERIC MAP (file_name => BIAS_FILE)
        PORT MAP (ADDR => b_addr, CLK => clk, data => b_data);

    mac0 : ENTITY work.mac
        PORT MAP (CLK => clk, PIXEL => pixel, WEIGHT => w_data, BIAS => b_data,
                  load => load, en => en, acc_out => acc);
    rq : ENTITY work.requant
        GENERIC MAP (K => K)
        PORT MAP (Z => acc, H => h_new);

    am : ENTITY work.argmax
        PORT MAP (CLK => clk, CLEAR => am_clr, EN => am_en, SCORE => acc,
                  idx => n_idx, digit => digit);
END rtl;