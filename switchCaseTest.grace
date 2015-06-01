// Ian Van Houdt

print "Testing the 'Switch...Case' implementation for Grace"

def x = 123

switch(x)
    case { 0 -> print "Zero" }
    case { 5 -> print "Five" }
    case { 10 -> print "Ten" }
    case { _ -> print "did not match" }

