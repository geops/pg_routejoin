
class Table(object):
    def __init__(self, name, schema):
        self.name = name
        self.schema = schema
        self.jointype = None

        # a set do collect joins
        self.joins = set()

    def __eq__(self, other):
        return (self.name == other.name and self.schema == other.schema)

    def __ne__(self, other):
        return not self.__eq__(other)

    def add_join(self, cols1, cols2):
        join_cols = zip(cols1, cols2)
        for join_col in join_cols:
            join_col = list(join_col)
            join_col.sort()  # sort them to make the set unique
            self.joins.add(tuple(join_col))

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
        joinlist = list(self.joins)
        joined_columns = map(lambda x: " = ".join(x), joinlist)
        return "%s %s on %s" % (self.jointype if self.jointype != None else "join", self.fullname, ' and '.join(joined_columns))
