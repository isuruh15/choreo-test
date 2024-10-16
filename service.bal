import ballerina/http;
import ballerina/uuid;
import ballerinax/health.fhir.r4.international401;
import ballerina/log;
import ballerinax/health.fhir.r4;


isolated http:Client statusClient = check new ("https://bulk-data.smarthealthit.org");

service / on new http:Listener(9080) {

    isolated resource function post export(
            @http:Payload MatchedPatient[] matchedPatients,
            @http:Query string? _outputFormat,
            @http:Query string? _since,
            @http:Query string? _type) returns http:Response|http:ClientError {

        string taskId = uuid:createType1AsString();
        boolean isSuccess = false;
        http:Response|http:ClientError status;
        string contextPath = "/eyJlcnIiOiIiLCJwYWdlIjoxMDAwMCwiZHVyIjoxMCwidGx0IjoxNSwibSI6MSwic3R1Ijo0LCJkZWwiOjAsInNlY3VyZSI6MH0/fhir";

        log:printInfo("Bulk exporting started. Sending Kick-off request.");
        do {
            international401:Parameters parametersResource = populateParamsResource(matchedPatients, _outputFormat, _since, _type);
            // kick-off request to the bulk export server
            log:printInfo(string `URL: ${contextPath}/Patient/$export`);
            log:printInfo(parametersResource.clone().toBalString());

            lock {
                status = statusClient->post(string `${contextPath}/Patient/$export`, parametersResource.clone().toJson(),
                {
                    Accept: "application/fhir+json",
                    Prefer: "respond-async",
                    ContentType: "application/json"
                });
            }
        }
        return status;
    }

}

public isolated function populateParamsResource(MatchedPatient[] matchedPatients, string? _outputFormat, string? _since, string? _type) returns international401:Parameters {

    international401:Parameters r4Parameters = {'parameter: []};
    international401:ParametersParameter[] paramsArr = [];

    if matchedPatients != [] {
        foreach MatchedPatient patient in matchedPatients {
            string patientReference = string `Patient/${patient.id}`;
            r4:Reference patientRef = {reference: patientReference};
            paramsArr.push({name: "patient", valueReference: patientRef});
        }
    }

    if _outputFormat is string {
        paramsArr.push({name: "_outputFormat", valueString: _outputFormat});

    }
    if _since is string {
        paramsArr.push({name: "_since", valueInstant: _since});
    }
    if _type is string {
        paramsArr.push({name: "_type", valueString: _type});
    }

    r4Parameters.'parameter = paramsArr;
    return r4Parameters;
}
