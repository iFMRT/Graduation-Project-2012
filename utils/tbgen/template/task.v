    task {& task_name &};{% each width_ports %}
        input {& it &};{% end %}

        begin
            if({% each ports%}({& it &}  === _{& it &})  &&
               {% end %}({& last_port &}  === _{& last_port &})
              ) begin
                $display("Test Succeeded !");
            end else begin
                $display("Test Failed !");
            end
        end
    endtask
