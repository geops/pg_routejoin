

def sanitize_pg_array(pg_array):
    """
    convert a array-string to a python list

    PG <9.0 used comma-aperated strings as array datatype. this function
    will convert those to list. if pg_array is not a tring, it will not
    be modified
    """
    if not type(pg_array) in (str,unicode):
        return pg_array
    # only for one-dimesional arrays
    return map(str.strip, pg_array.strip("{}").split(","))
