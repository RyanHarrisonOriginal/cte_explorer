SQL_SYNTAX_REMOVAL = [
    (r'except\((\w*)\)',r' /*except \1*/'),
    (r'using\((\w*)\)',r' on lt.\1 = rt.\1 /*converting using() function to traditional join*/')
]