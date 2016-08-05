import "mirrors" as mirror

method methodsIn(DesiredType) missingFrom (value) -> String {
    def vMethods = mirror.reflect(value).methodNames
    def tMethods = DesiredType.methodNames
    def missing = (tMethods -- vMethods).asList.sort
    if (missing.size == 0) then {
        ProgrammingError.raise "{value.asDebugString} seems to have all the methods of {DesiredType}"
    } else {
        var s := ""
        missing.do { each -> s := s ++ each } 
            separatedBy { s := s ++ ", " }
        s
    }
}
method protocolOf(value) notCoveredBy (Q:Type) -> String  {
    var s := ""
    def vMethods = set(mirror.reflect(value).methodNames)
    def qMethods = set(Q.methodNames)
    def missing = (vMethods -- qMethods).filter{m -> 
        (! m.endsWith "$object(1)") && (m != "outer")}.asList.sort
    if (missing.isEmpty.not) then {
        s := ""
        missing.do { each -> s := s ++ each } 
            separatedBy { s := s ++ ", " }
    }
    return s
}
