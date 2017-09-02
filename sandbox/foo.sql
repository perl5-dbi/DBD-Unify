create table foo (
    PRIMARY KEY (c_foo, v_foo),
     c_foo	NUMERIC (9) NOT NULL,
     v_foo	NUMERIC (2) NOT NULL,
    s_foo	CHAR (4)    NOT NULL,
    a_foo	AMOUNT (6, 2),
    f_foo	FLOAT,
    r_foo	REAL,
    d_foo	DATE,
    t_foo	TIME,
    b_foo	BINARY
    );
