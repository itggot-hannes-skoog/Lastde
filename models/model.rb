class Model
  def self.table_name(name)
    @table_name = name
  end

  def self.column(name)
    @columns ||= []
    @columns << name
  end

  def self.get(&block)
    conditions = []
    if block_given?
      block = block.call
      if block[:join]
        join_result = Model.join(block[:join], @table_name)
        join = join_result[0]
        only = join_result[1]
        conditions += join_result[2]
      end
      if block[:where]
        where_result = Model.where(block[:where])
        where = where_result[0]
        conditions += where_result[1]
      end
      if block[:order]
        order = "ORDER BY #{block[:order][:type]}(#{block[:order][:what]}) #{block[:order][:order]}"
      end
    end
    db = SQLite3::Database.new "database.db"
    p "SELECT #{@table_name}.*#{only} FROM #{@table_name} #{join} #{where} #{order}"
    result = db.execute("SELECT #{@table_name}.*#{only}
                          FROM #{@table_name} #{join} #{where} #{order}",
                        conditions)
    result.map { |item| new(item) }
  end

  def self.where(data)
    conditions = []
    wheres = data
    first = wheres.slice!(0)
    first[:table] ? table = "#{first[:table]}." : table = ""
    if first[:is]
      where = "WHERE #{table}#{first[:what]} = ?"
      conditions << first[:is]
    else
      where = "WHERE #{table}#{first[:what]} LIKE ?"
      conditions << first[:like]
    end
    if !wheres.empty?
      wheres.each do |item|
        item[:table] ? table = "#{item[:table]}." : table = ""
        where += " AND #{table}#{item[:what]} = ?"
        conditions << item[:is]
      end
    end
    return [where, conditions]
  end

  def self.join(data, table_name)
    conditions = []
    join = ""
    order = ""
    only = ""
    on = ""
    data.each do |join_block|
      if join_block[:condition]
        if join_block[:type]
          join += " #{join_block[:type]} JOIN #{join_block[:name]} "
        else
          join += " JOIN #{join_block[:name]}"
        end
        if join_block[:on]
          on_array = join_block[:on]
          first = on_array.slice!(0)
          if first[1][:table]
            on = " ON #{join_block[:name]}.#{first[0]} = #{table_name}.#{first[1][:name]}"
          else
            on = " ON #{join_block[:name]}.#{first[0]} = ?"
            conditions << first[1][:name]
          end
          if !on_array.empty?
            on_array.each do |element|
              if element[1][:table]
                on += " AND #{join_block[:name]}.#{element[0]} = #{table_name}.#{element[1][:name]}"
              else
                on += " AND #{join_block[:name]}.#{element[0]} = ?"
                conditions << element[1][:name]
              end
            end
          end
          join += on
        end
        if join_block[:only]
          if join_block[:only] != "none"
            join_block[:only].each do |thing|
              only += ", #{join_block[:name]}.#{thing}"
            end
          end
        else
          only = ", #{join_block[:name]}.*"
        end
      end
    end
    return [join, only, conditions]
  end
end
