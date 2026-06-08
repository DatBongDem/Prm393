package be.business.dtos;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public class AIResponse {

    private String type;        // chat | query | aggregate | irrelevant
    private String field;       // total, project, finalExam...
    private String operator;    // > < =
    private String value;

    private String aggregate;   // max / min
    private String className;   // SE1813

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getField() { return field; }
    public void setField(String field) { this.field = field; }

    public String getOperator() { return operator; }
    public void setOperator(String operator) { this.operator = operator; }

    public String getValue() { return value; }
    public void setValue(String value) { this.value = value; }

    public String getAggregate() { return aggregate; }
    public void setAggregate(String aggregate) { this.aggregate = aggregate; }

    public String getClassName() { return className; }
    public void setClassName(String className) { this.className = className; }
}