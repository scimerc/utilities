function clone(rhs, lhs) {
    if ( isarray(rhs) ) {
        for (i in rhs) {
            if (isarray(rhs[i])) {
                lhs[i][1] = ""
                delete lhs[i][1]
                clone(lhs[i], rhs[i])
            } else {
                lhs[i] = rhs[i]
            }
        }
    } else {
        lhs = rhs
    }
}
