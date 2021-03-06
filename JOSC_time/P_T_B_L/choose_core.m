function [result_opti_core,TT,vehicle_position_delete_right,vehicle_position_delete_left,j_selection,vehicle_position_task]=choose_core(F_limit_core,N_right_add,N_left_add,M,L_m,v_speed,B_RSU,P_v,N_v,c_car,recy_time,Z_L_m,Time_delay,V_postion_x_right_initial,V_postion_y_right_initial,V_postion_x_left_initial,V_postion_y_left_initial)
    M_C=4*M;                      % The number of cores          
    V_positon_x_right_add= 0.5*ones(N_right_add,1);
    V_positon_y_right_add= rand(N_right_add,1);

for ii=1: N_right_add
    if V_positon_y_right_add(ii) >=0.5
        V_positon_y_right_add(ii)=8;
    else
        V_positon_y_right_add(ii)=6;
    end
end
%the car added to the direction left

V_postion_x_left_add=7*Z_L_m*ones(N_left_add,1);
V_postion_y_left_add =rand(N_left_add,1);
for ii=1:N_left_add
    if V_postion_y_left_add(ii) >=0.5
        V_postion_y_left_add(ii)=4;
    else
        V_postion_y_left_add(ii)=2;
    end
end



% the total car position
V_postion_x_right_initial=V_postion_x_right_initial+v_speed* recy_time;
V_postion_x_left_initial =V_postion_x_left_initial -v_speed* recy_time;

%take out the car not in the range 
for ii= 1: length(V_postion_x_right_initial)
    if (V_postion_x_right_initial(ii)>= 0) && (V_postion_x_right_initial(ii)<= 6*Z_L_m)
        V_postion_x_right_initial(ii)=V_postion_x_right_initial(ii);
    else
        V_postion_x_right_initial(ii)=0;
    end
end

for ii= 1: length(V_postion_x_left_initial)
    if (V_postion_x_left_initial(ii)>= Z_L_m) && (V_postion_x_left_initial(ii)<= 7*Z_L_m)
        V_postion_x_left_initial(ii)=V_postion_x_left_initial(ii);
    else
        V_postion_x_left_initial(ii)=0;
    end
end

%update
vehicle_position_initial=[V_postion_x_right_initial, V_postion_y_right_initial ;V_postion_x_left_initial,V_postion_y_left_initial];
vehicle_position_now=[V_positon_x_right_add,V_positon_y_right_add;vehicle_position_initial;V_postion_x_left_add,V_postion_y_left_add];
vehicle_position_delete=vehicle_position_now;
delete_index=find(vehicle_position_delete(:,1)==0);
vehicle_position_delete([delete_index],:)=[];

%not each car has one task, it has probability to have task 
task_proba=rand(length(vehicle_position_delete),1);
vehicle_position_delete=[vehicle_position_delete,task_proba];

for ii=1:length(vehicle_position_delete)
    if vehicle_position_delete(ii,3)<=0.6
        vehicle_position_delete(ii,3)=1;
    else 
        vehicle_position_delete(ii,3)=0;
    end
end    

vehicle_position_task = vehicle_position_delete;
delete_car_index=find(vehicle_position_task(:,3)==0);
vehicle_position_task([delete_car_index],:)=[];

% get the number of car right and left
N_right=0; 
for ii=1: length(vehicle_position_task)
    if (vehicle_position_task(ii,2) == 6 ) ||  (vehicle_position_task(ii,2)==8 )
        
        N_right =N_right+1;
    end
end
vehicle_position_delete_right = vehicle_position_task(1:N_right,:);

N_left=0;
for ii=1: length(vehicle_position_task)
    if (vehicle_position_task(ii,2) == 2 ) ||  (vehicle_position_task(ii,2)==4 )
        N_left =N_left+1;
    end
end
vehicle_position_delete_left = vehicle_position_task(N_right+1:end,:);



% Driving Time 
L_all_right=zeros(N_right,M);
for ii=1:N_right
    for jj=1:M
        L_all_right(ii,jj)= -vehicle_position_delete_right(ii)+L_m*(jj-1);

    end
end

L_all_left=zeros(N_left,M);
for ii=1:N_left
    for jj=1:M
        L_all_left(ii,jj)=vehicle_position_delete_left(ii)-L_m*jj;

     end
end
L_all=[L_all_right ; L_all_left];  
L_all_core=zeros(length(vehicle_position_task),M_C);
for ii=1:M
   L_all_core(:,4*ii-3:4*ii)=repmat(L_all(:,ii),1,4); 
end


T_d_all = (zeros(length(vehicle_position_task),M_C+1));
for ii = 1:length(vehicle_position_task)
    T_d_all(ii,2:end) = L_all_core(ii,:) ./ v_speed;
end 

%communication time 
h_length= vehicle_position_task(:,2);
w_length=10*ones(length(vehicle_position_task),1);
dataSize = (100+200*rand(length(vehicle_position_task),1));

d_t=sqrt(w_length.^2+h_length.^2);
r_c= B_RSU* log2(1+(P_v *  (d_t.^(-2.5))  )/N_v);
T_c= dataSize./r_c;
% 
T_c_all = zeros(length(vehicle_position_task),M_C+1);
for ii = 2:M_C+1
    T_c_all(:,ii) = T_c;
end
% 
% % The computing time
c_i=0.5+rand(length(vehicle_position_task),1);
c_i_all = ones(length(vehicle_position_task),M_C+1);
for ii = 1:M_C+1
    c_i_all(:,ii) = c_i;
end  
T_max = (8+2*rand(length(vehicle_position_task),1));
f_ij_all= 15/4*ones(length(vehicle_position_task),M_C);

T_v_all=zeros(length(vehicle_position_task),M_C+1);
T_v_all(:,1) = c_i_all(:,1) / c_car;
T_v_all(:,2:end) = c_i_all(:,2:end) ./ f_ij_all;

Time_delay= repmat(Time_delay,length(vehicle_position_task),1);




cvx_begin
    cvx_solver MOSEK
    variable j_selection(length(vehicle_position_task),M_C+1) binary;
    expression TT;
%     TT=(j_selection.*(T_d_all+T_c_all+Time_delay));
%     TT(:,1)=TT(:,1)+j_selection(:,1).*(c_i_all(:,1) / c_car);
%     
%     for ii=1:length(vehicle_position_task)
%         for jj=1:M
%             TT(ii,jj+1)=TT(ii,jj+1)+ c_i_all(ii,jj+1)*quad_over_lin(j_selection(ii,jj+1),f_ij_all(ii,jj));
%         end
%     end
    TT=j_selection.*(T_d_all+T_c_all+Time_delay+T_v_all);
    TT(:,1)=TT(:,1)+j_selection(:,1).*(c_i_all(:,1) / c_car);
    minimize sum(sum(TT));
        
    for ii = 1:length(vehicle_position_task)
        sum(j_selection(ii,:))==1;          %condition (8c)
    end
    
    sum(j_selection(:,2:end).*f_ij_all) <= F_limit_core;                 %condition (8d)
    
    sum(TT,2)<= T_max;  %condition (9b)
    
    sum(j_selection(:,2:end))<=1;
    
    
    for ii= 1:length(vehicle_position_task)
         for jj= 1:M_C
            if L_all_core(ii,jj)<0
                j_selection(ii,jj+1)==0;
            end
         end
    end
    
      for ii= 1:length(vehicle_position_task)
        for jj= 1:M_C
          if L_all_core(ii,jj)> 4*L_m
              j_selection(ii,jj+1)==0;
          end
        end
      end
    
cvx_end


result_opti_core=cvx_optval;  

end