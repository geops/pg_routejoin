


class BaseJoin(object):
  """
  represents a join

  this class should not be used directly - use its subclasses
  Join and LeftJoin
  """

  def __init__(self, table_1, table_2, table_schema_1, table_schema_2, table_columns_1, table_columns_2):
    """
    the columns_1 and columns_2 variables as lists of the 
    columns to join. they are joined by their order
     col_t1_1 on col_t2_1
     col_t1_2 on col_t2_2
    """
    self.table_1 = table_1
    self.table_2 = table_2
    self.table_schema_1 = table_schema_1
    self.table_schema_2 = table_schema_2
    self.table_columns_1 = table_columns_1
    self.table_columns_2 = table_columns_2
    self.join_type = ""

  def __eq__(self, other):
    # ignore the join type on this comparisson
    return ((self.table_1 == other.table_1 and 
            self.table_schema_1 == other.table_schema_1 and
            self.table_columns_1 == other.table_columns_1 and
            self.table_2 == other.table_2 and 
            self.table_schema_2 == other.table_schema_2 and
            self.table_columns_2 == other.table_columns_2) or
           (self.table_1 == other.table_2 and 
            self.table_schema_1 == other.table_schema_2 and
            self.table_columns_1 == other.table_columns_2 and
            self.table_2 == other.table_1 and 
            self.table_schema_2 == other.table_schema_1 and
            self.table_columns_2 == other.table_columns_1))

  def __ne__(self, other):
    return not self.__eq__(other)

  def toSql(self, is_first=False):
    sql = ""
    # include the table after "FROM " when is_first is true
    if is_first:
      sql += "\"%s\".\"%s\"" % (self.table_schema_1, self.table_1)

    sql += " %s \"%s\".\"%s\" on " % (
      self.join_type, 
      self.table_schema_2,
      self.table_2)

    # columns 
    columns = zip(self.table_columns_1, self.table_columns_2)
    column_sqls = []
    for c1, c2 in columns:
      # asuming the table names are uniquw in the constructed
      # sql query. maybe fix this later 
      column_sqls.append("\"%s\".\"%s\" = \"%s\".\"%s\"" % (
        self.table_1,
        c1,
        self.table_2,
        c2))

    sql += " and ".join(column_sqls) + " "
    return sql



class Join(BaseJoin):
  def __init__(self, *args, **kwargs):
    BaseJoin.__init__(self, *args, **kwargs)
    self.join_type = "join"


class LeftJoin(BaseJoin):
  def __init__(self, *args, **kwargs):
    BaseJoin.__init__(self, *args, **kwargs)
    self.join_type = "left join"
