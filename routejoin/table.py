
class Table(object):
  def __init__(self, name, schema):
    self.name = name
    self.schema = schema
    self.jointype = None

    # a list do collect joins
    # format (('tablex.col1', 'tabley.col2'), ('tablex.col2', 'tabley.col2'))
    self.joins = []

  def __eq__(self, other):
    return (self.name == other.name and self.schema == other.schema)

  def __ne__(self, other):
    return not self.__eq__(other)

  @property
  def fullname(self):
    return "\"%s\".\"%s\"" % (self.schema, self.name)

  @property
  def alias(self):
    """
    for later alias support
    """
    return "\"%s\"" % self.name

  def prepend_alias(self, columns):
    """
    prepend the table alias to a list
    of column names
    """
    return map(lambda x: "%s.\"%s\"" % (self.alias, x), columns)

  @property
  def joinsql(self):
    joined_columns = map(lambda x: " = ".join(x), self.joins)
    return "%s %s on %s" % (self.jointype if self.jointype!=None else "join", self.fullname, ' and '.join(joined_columns))
