/******** Time scale ********/
`timescale 1ns/1ps
{{ header }}
    /******** Define Simulation Loop********/
    parameter             STEP = 10;

    /******** Generate Clock ********/
    always #(STEP / 2) begin
        clk <= ~clk;
    end

    assign clk_ = ~clk;

    {{ dut }}

    task {{ task_name }};{% for it in width_ports %}
        input {{ it }};{% endfor %}

        begin
            if({% for it in ports%}({{ it }}  === _{{ it }})  &&
               {% endfor %}({{ last_port }}  === _{{ last_port }})
              ) begin
                $display("Test Succeeded !");
            end else begin
                $display("Test Failed !");
            end
        end

    endtask

    /******** Test Case ********/
    initial begin
        # 0 begin
            {% for item in first_case  %}{{item}}
            {% endfor %}end
        # (STEP * 3/4){% for case_pair in testcase  %}
        # STEP begin{% for case in case_pair  %}
            {% for item in case  %}{{item}}
           {% endfor %}{% endfor %}end
        {% endfor %}# STEP begin
            {% for item in last_case  %}{{item}}
            {% endfor %}$finish;
        end
    end{{ footer }}
