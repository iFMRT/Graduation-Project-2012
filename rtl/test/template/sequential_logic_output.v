/******** Time scale ********/
`timescale 1ns/1ps
{{ header }}
    /******** Define Simulation Loop********/
    parameter             STEP = 10;

    /******** Generate Clock ********/
    always #(STEP / 2) begin
        clk <= ~clk;
    end

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
            clk      <= 1'h1;
            reset    <= `ENABLE;
       end
        # (STEP * 3/4)
        # STEP begin
            reset <= `DISABLE;
        end
       {% for case_list in testcase  %}
       # STEP begin
            {% for item in case_list  %}{{item}}
            {% endfor %}end
        {% endfor %}
       # STEP begin
           $finish;
       end                      // 
    end{{ footer }}
