

def sanitize_pg_array(pg_array):
    """
    convert a array-string to a python list
    """
    # only for one-dimesional arrays
    return map(str.strip, pg_array.strip("{}").split(","))
