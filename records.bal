public type MatchedPatient record {|
    string id;
    string canonical?;
    map<string> identifiers?;
|};