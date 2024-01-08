CREATE TABLE lists (
    id serial primary key ,
    name text unique not null
);

CREATE TABLE todos (
    id serial primary key ,
    name text not null ,
    completed boolean not null default false,
    list_id integer not null references list(id)
);
