create table a1 (
    f1  numeric (9) not null,
    f2  numeric (9) not null
    );

select * from SYS.ACCESSIBLE_TABLES where TABLE_NAME = 'a1';

create table a2 (
    f1  numeric (9) not null configuration (direct key base 1),
    f2  numeric (9) not null
    );

select * from SYS.ACCESSIBLE_TABLES where TABLE_NAME = 'a2';
