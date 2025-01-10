-- Return 1 if number is positive, returns 0 if number is zero, and returns -1 otherwise.
function sign(number)
    return (number > 0 and 1) or (number == 0 and 0) or -1
end