require 'pg'

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: "todos")
          end
    @logger = logger
  end

  def query(statement, *params)
    @logger.info("#{statement}: #{params}")
    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = 'SELECT * FROM lists where id = $1'
    result = query(sql, id)

    tuple = result.first

    list_id = tuple["id"].to_i
    todos = find_todos_for_list(list_id)
    {id: tuple["id"], name: tuple["name"], todos: todos}
  end

  def all_lists
    sql = "SELECT * FROM lists"
    result = query(sql)

    result.map do |tuple|
      list_id = tuple["id"].to_i
      todos = find_todos_for_list(list_id)
      {id: list_id, name: tuple["name"], todos: todos}
    end
  end

  def create_new_list(list_name)
    sql = "INSERT INTO lists (name) VALUES ($1)"
    query(sql, list_name)
  end

  def delete_list(id)
    query("DELETE FROM todos WHERE list_id = $1;", id)
    query("DELETE FROM lists WHERE id = $1;", id)
  end

  def update_list_name(id, new_name)
    query('UPDATE lists SET name = $1 WHERE id = $2;', new_name, id)
  end

  def create_new_todo(list_id, todo_name)
    sql = "insert into todos (list_id, name) values ($1, $2);"
    query(sql, list_id, todo_name)
  end

  def delete_todo_from_list(list_id, todo_id)
    sql = 'DELETE FROM todos WHERE list_id = $1 AND id = $2'
    query(sql, list_id, todo_id)
  end

  def update_todo_status(list_id, todo_id, new_status)
    sql = 'UPDATE todos SET completed = $1 WHERE list_id = $2 AND id = $3;'
    query(sql, new_status, list_id, todo_id)
  end

  def mark_all_todos_as_completed(list_id)
    sql = 'UPDATE todos SET completed = true WHERE list_id = $1;'
    query(sql, list_id)

    # list = find_list(list_id)
    # list[:todos].each do |todo|
    #   todo[:completed] = true
    # end
  end

  private

  def find_todos_for_list(list_id)
    todo_sql = "SELECT * FROM todos WHERE list_id = $1"
    todos_result = query(todo_sql, list_id )

    todos_result.map do |todo_tuple|
      {id: todo_tuple["id"].to_i,
       name: todo_tuple["name"],
       completed: todo_tuple["completed"] == 't' }
    end
  end
end
