function y = match_twoimages(image1, image2, F1, F2)
[Measure, Scale] = vl_ubcmatch(F1.d,F2.d) ;
[row2, region, contour] = unique(Measure(2,:));
row1 = Measure(1,region);
Measure = [row1; row2];
numM = size(Measure,2) ;
if numM == 0
    y.ransac = 0;
    return
end
out1 = F1.f(1:2,Measure(1,:)) ; out1(3,:) = 1 ;
out2 = F2.f(1:2,Measure(2,:)) ; out2(3,:) = 1 ;
clear high_score score best ;
radius = 6;
for n = 1:100
  s_region = vl_colsubset(1:numM, 4) ;
  g_region = [] ;
  for i = s_region
    g_region = cat(1, g_region, kron(out1(:,i)', vl_hat(out2(:,i)))) ;
  end
  [ultra,sum_c,volumn] = svd(g_region) ;
  high_score{n} = reshape(volumn(:,9),3,3) ;
  out2_ = high_score{n} * out1 ;
  deltax = out2_(1,:)./out2_(3,:) - out2(1,:)./out2(3,:) ;
  deltay = out2_(2,:)./out2_(3,:) - out2(2,:)./out2(3,:) ;
  best{n} = (deltax.*deltax + deltay.*deltay) < radius*radius ;
  score(n) = sum(best{n}) ;
end
[sum_c, b] = max(score) ;
high_score = high_score{b} ;
best = best{b} ;
if exist('fminsearch') == 2
  high_score = high_score / high_score(3,3) ;
  opts = optimset('Display', 'none', 'TolFun', 1e-8, 'TolX', 1e-8) ;
  high_score(1:8) = fminsearch(@sum_error, high_score(1:8)', opts) ;
else
  warning('Refinement disabled as fminsearch was not found.') ;
end
feature1=F1.f;feature2=F2.f;
delta1 = max(size(image2,1)-size(image1,1),0) ;
delta2 = max(size(image1,1)-size(image2,1),0) ;
figure ; clf ;
% subplot(2,1,1) ;
imshow([padarray(image1,delta1,'post') padarray(image2,delta2,'post')]) ;
o = size(image1,2) ;
figure ; clf ;
imshow([padarray(image1,delta1,'post') padarray(image2,delta2,'post')]) ;
hold on;
feature_v1 = vl_plotframe(F1.f) ;
feature_v2 = vl_plotframe(F1.f) ;
set(feature_v1,'color','k','linewidth',3) ;
set(feature_v2,'color','y','linewidth',2) ;
ff=feature2;
ff(1, :) = ff(1, :) + o;
feature_v1 = vl_plotframe(ff) ;
feature_v2 = vl_plotframe(ff) ;
set(feature_v1,'color','k','linewidth',3) ;
set(feature_v2,'color','y','linewidth',2) ;
figure ; clf ;
imshow([padarray(image1,delta1,'post') padarray(image2,delta2,'post')]) ;
hold on;
plot([feature1(1,Measure(1,:));feature2(1,Measure(2,:))+o], ...
     [feature1(2,Measure(1,:));feature2(2,Measure(2,:))], ['k' '-'],  'LineWidth', 2) ;
plot([feature1(1,Measure(1,:)) + 1;feature2(1,Measure(2,:))+o+1], ...
     [feature1(2,Measure(1,:)) + 1;feature2(2,Measure(2,:))+1], ['y' '-'],  'LineWidth', 2) ;
plot(feature1(1,Measure(1,:)), feature1(2,Measure(1,:)), 'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'k'); 
plot(feature1(1,Measure(1,:))+1, feature1(2,Measure(1,:))+1, 'yo', 'MarkerSize', 5, 'MarkerFaceColor', 'y'); 
plot(feature2(1,Measure(2,:))+o, feature2(2,Measure(2,:)), 'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'k');
plot(feature2(1,Measure(2,:))+o+1, feature2(2,Measure(2,:))+1, 'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'y');
figure ; clf ;
imshow([padarray(image1,delta1,'post') padarray(image2,delta2,'post')]) ;
o = size(image1,2) ;
hold on;
plot([feature1(1,Measure(1,best));feature2(1,Measure(2,best))+o], ...
     [feature1(2,Measure(1,best));feature2(2,Measure(2,best))], ['k' '-'],  'LineWidth', 2) ;
plot([feature1(1,Measure(1,best))+1;feature2(1,Measure(2,best))+o+1], ...
     [feature1(2,Measure(1,best))+1;feature2(2,Measure(2,best))+1], ['y' '-'],  'LineWidth', 2) ;  
plot(feature1(1,Measure(1,best)), feature1(2,Measure(1,best)), 'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'k'); 
plot(feature1(1,Measure(1,best))+1, feature1(2,Measure(1,best))+1, 'yo', 'MarkerSize', 5, 'MarkerFaceColor', 'y'); 
plot(feature2(1,Measure(2,best))+o, feature2(2,Measure(2,best)), 'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'k');
plot(feature2(1,Measure(2,best))+o+1, feature2(2,Measure(2,best))+1, 'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'y');
drawnow ;
y.ransac = sum(best);
end
function E = sum_error(input)
 cal1 = input(1) * out1(1,best) + input(4) * out1(2,best) + input(7) ;
 cal2 = input(2) * out1(1,best) + input(5) * out1(2,best) + input(8) ;
 cal3 = input(3) * out1(1,best) + input(6) * out1(2,best) + 1 ;
 deltax = out2(1,best) - cal1 ./ cal3 ;
 deltay = out2(2,best) - cal2 ./ cal3 ;
 E = sum(deltax.*deltax + deltay.*deltay) ;
end