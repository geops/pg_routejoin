

def sanitize_pg_array(pg_array):
    """
    convert a array-string to a python list
    """
    # only for one-dimesional arrays
    if not type(pg_array) in (str,unicode):
        return pg_array
    return map(str.strip, pg_array.strip("{}").split(","))
