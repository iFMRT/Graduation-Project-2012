/******** Test Case ********/
initial begin
    {% for case_list in testcase  %}
    # STEP begin
        {% for item in case_list  %}{{item}}
        {% endfor %}end
    {% endfor %}
end