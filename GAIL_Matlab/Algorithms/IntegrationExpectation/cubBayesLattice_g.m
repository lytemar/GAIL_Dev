%CUBBAYESLATTICE_G Bayesian cubature method to estimate the integral
% of a random variable
%
%   OBJ = CUBBAYESLATTICE_G('f',f,'dim',dim,'absTol',absTol,'relTol',relTol,...
%         'order',order, 'ptransform',ptransform, 'arbMean',arbMean);
%   Initializes the object with the given parameters.
%
%   [Q,OutP] = COMPINTEG(OBJ); estimates the integral of f over hyperbox
%   [0,1]^d using rank-1 Lattice sampling to within a specified generalized
%   error tolerance, tolfun = max(abstol, reltol*| I |), i.e., | I - Q | <= tolfun
%   with confidence of at least 99%, where I is the true integral value,
%   Q is the estimated integral value, abstol is the absolute error tolerance,
%   and reltol is the relative error tolerance. Usually the reltol determines
%   the accuracy of the estimation, however, if | I | is rather small,
%   then abstol determines the accuracy of the estimation.
%   OutP is the structure holding additional output params, more details provided
%   below. Input f is a function handle that accepts an n x d matrix input,
%   where d is the dimension of the hyperbox, and n is the number of points
%   being evaluated simultaneously.
%
%   Input Arguments
%
%     f --- the integrand.
%     dim --- number of dimensions of the integrand.
%
%   Optional Input Arguments
%     absTol --- absolute error tolerance | I - Q | <= absTol. Default is 0.01.
%     relTol --- relative error tolerance | I - Q | <= I*relTol. Default is 0.
%     order --- order of the Bernoulli polynomial of the kernel: r=1,2
%     ptransform --- periodization variable transform to use: 'Baker',
%     'C0', 'C1', 'C1sin', or 'C2sin'. Default is 'C1sin'
%     arbMean --- If false, the algorithm assumes the integrand was sampled
%                 from a Gaussian process of zero mean. Default is True.
%     alpha --- confidence level for a credible interval of Q. Default is 0.01.
%     mmin --- min number of samples to start with = 2^mmin
%     mmax --- max number of samples allowed = 2^mmax
%
%   Output Arguments
%    OutP.n --- number of samples used to compute the integral of f.
%    OutP.time --- time to compute the integral in seconds.
%    OutP.exitFlag --- indicates the exit condition of the algorithm:
%                      1 - integral computed within the error tolerance and
%                      without exceeding max sample limit 2^mmax
%                      2 - used max number of samples and yet not met the
%                      error tolerance
%    OutP.ErrBd  --- estimated integral error | I - Q |
%
%
%  Guarantee
% This algorithm attempts to calculate the integral of function f over the
% hyperbox [0,1]^dim to a prescribed error tolerance tolfun:= max(abstol,reltol*| I |)
% with guaranteed confidence level, e.g., 99% when alpha=0.5%. If the
% algorithm terminates without showing any warning messages and provides
% an answer Q, then the following inequality would be satisfied:
%
% Pr(| Q - I | <= tolfun) = 99%
%
% Please refer to our paper (1) for detailed arguments and proofs.
%
%  Examples
%
% Example 1:
%
% If no parameters are parsed, help text will show up as follows:
% >> help cubBayesLattice_g
% ***Bayesian cubature method to estimate the integral ***
%
%
% Example 2: Quadratic
%
% Estimate the integral with integrand f(x) = x.^2 over the interval [0,1]
% with default parameters: order=2, ptransform=C1sin, abstol=0.01, relTol=0
%
% >> warning('off','GAIL:cubBayesLattice_g:fdnotgiven')
% >> obj = cubBayesLattice_g;
% >> exactInteg = 1.0/3;
% >> muhat=compInteg(obj);
% >> warning('on','GAIL:cubBayesLattice_g:fdnotgiven')
% >> check = double(abs(exactInteg-muhat) < 0.01)
% check = 1
%
%
% Example 3: ExpCos
%
% Estimate the integral with integrand f(x) = exp(sum(cos(2*pi*x)) over the
% interval [0,1] with parameters: order=2, ptransform=C1sin, abstol=0.001,
% relTol=0.01
%
% >> fun = @(x) exp(sum(cos(2*pi*x), 2));
% >> dim=2; absTol=1e-3; relTol=1e-2;
% >> exactInteg = besseli(0,1)^dim;
% >> inputArgs = {'relTol',relTol, 'order',2, 'ptransform','C1sin'};
% >> inputArgs = [inputArgs {'f',fun, 'dim',dim, 'absTol',absTol,}];
% >> obj=cubBayesLattice_g(inputArgs{:});
% >> muhat=compInteg(obj);
% >> check = double(abs(exactInteg-muhat) < max(absTol,relTol*abs(exactInteg)))
% check = 1
%
%
% Example 3: Keister function
%
% >> dim=2; absTol=1e-3; relTol=1e-2;
% >> normsqd = @(t) sum(t.*t,2); %squared l_2 norm of t
% >> replaceZeros = @(t) (t+(t==0)*eps); % to avoid getting infinity, NaN
% >> yinv = @(t)(erfcinv( replaceZeros(abs(t)) ));
% >> f1 = @(t,dim) cos( sqrt( normsqd(yinv(t)) )) *(sqrt(pi))^dim;
% >> fKeister = @(x) f1(x,dim); exactInteg = Keistertrue(dim);
% >> inputArgs ={'f',fKeister,'dim',dim,'absTol',absTol, 'relTol',relTol};
% >> inputArgs =[inputArgs {'order',2, 'ptransform','C1','arbMean',true}];
% >> obj=cubBayesLattice_g(inputArgs{:});
% >> muhat=compInteg(obj);
% >> check = double(abs(exactInteg-muhat) < max(absTol,relTol*abs(exactInteg)))
% check = 1
%
%
% Example 3: Multivariate normal probability
%
% >> dim=2; absTol=1e-3; relTol=1e-2; fName = 'MVN';
% >> C = [4 1 1; 0 1 0.5; 0 0 0.25]; MVNParams.Cov = C'*C; MVNParams.C = C;
% >> MVNParams.a = [-6 -2 -2]; MVNParams.b = [5 2 1]; MVNParams.mu = 0;
% >> MVNParams.CovProp.C = chol(MVNParams.Cov)';
% >> muBest = 0.676337324357787;
% >> integrand =@(t) GenzFunc(t,MVNParams);
% >> inputArgs={'f',integrand,'dim',dim, 'absTol',absTol,'relTol',relTol};
% >> inputArgs=[inputArgs {'order',1,'ptransform','C1sin','arbMean',true}];
% >> obj=cubBayesLattice_g(inputArgs{:});
% >> muhat = compInteg(obj);
% >> check = double(abs(muBest-muhat) < max(absTol,relTol*abs(muBest)))
% check = 1
%
%
%   See also CUBSOBOL_G, CUBLATTICE_G, CUBMC_G, MEANMC_G, INTEGRAL_G
%
%  References
%
%   [1] R. Jagadeeswaran and Fred J. Hickernell, "Faster Adaptive
%   Bayesian cubature using Lattice Sampling", 
%   https://arxiv.org/abs/1809.09803 (submitted).
%
%   [2] Sou-Cheng T. Choi, Yuhan Ding, Fred J. Hickernell, Lan Jiang, Lluis
%   Antoni Jimenez Rugama, Da Li, Jagadeeswaran Rathinavel, Xin Tong, Kan
%   Zhang, Yizhi Zhang, and Xuan Zhou, GAIL: Guaranteed Automatic
%   Integration Library (Version 2.2) [MATLAB Software], 2017. Available
%   from http://gailgithub.github.io/GAIL_Dev/
%
%   If you find GAIL helpful in your work, please support us by citing the
%   above papers, software, and materials.
%
%
classdef cubBayesLattice_g < handle
  properties
    f = @(x) x.^2; %function to integrate
    dim = 1; %dimension of the integrand
    absTol = 0.01; %absolute tolerance
    relTol = 0; %relative tolerance
    order = 2; %Bernoulli order of the kernel
    alpha = 0.01; % p-value, default 0.1%.
    ptransform = 'C1sin'; %periodization transform
    stopAtTol = true; %automatic mode: stop after meeting the error tolerance
    arbMean = true; %by default use zero mean algorithm
    stopCriterion = 'MLE'; % Available options {'MLE', 'GCV', 'full'}
    mmin = 4;  %10; %min number of samples to start with = 2^mmin
    mmax = 22; %max number of samples allowed = 2^mmax
  end
  
  properties (SetAccess = private)
    ff = []; %integrand after the periodization transform
    mvec = []; % n = 2^m
    uncert = 0;  % quantile value for the error bound
    gen_vec = []; % generator for the Lattice points
    
    fullBayes = false; % Full Bayes - assumes m and s^2 as hyperparameters,
    GCV = false; % Generalized cross validation
    vdc_order = true; % use Lattice points generated in vdc order
    kernType = 1; % Type-1: algebraic convergence, Type-2: exponential convergence
    
    % only for developers use
    fName = 'None'; %name of the integrand
    figSavePath = ''; %path where to save he figures
    visiblePlot = false; %make plots visible
    debugEnable = false; %enable debug prints
    gaussianCheckEnable = false; %enable plot to check Gaussian pdf
    avoidCancelError = true; % avoid cancellation error in stopping criterion
    
    % variables to save debug info in each iteration
    errorBdAll = [];
    muhatAll = [];
    aMLEAll = [];
    lossMLEAll = [];
    timeAll = [];
    dscAll = [];
    s_All = [];
  end
  
  methods
    function obj = cubBayesLattice_g(varargin)  %Constructor
      
      if nargin > 0
        iStart = 1;
        if isa(varargin{1},'cubBayesLattice_g')
          obj = copy(varargin{1});
          iStart = 2;
        end
        % parse each input argument passed
        if nargin >= iStart
          % parse and set the input arguments to obj
          obj.parse_input_args(varargin{:});
        end
      else
        obj.warn_fd();
      end
      
      if strcmp(obj.stopCriterion, 'full')
        % Full Bayes : The posterior error is a Student-t distribution
        obj.fullBayes = true;
      elseif strcmp(obj.stopCriterion, 'GCV')
        % use Generalized cross validation
        obj.GCV = true;
      else
        % use empirical Bayes : Maximum likelihood estimation
        obj.fullBayes = false;
        obj.GCV = false;
      end
      
      % Credible interval : two-sided confidence
      % i.e., 1-alpha percent quantile
      if obj.fullBayes
        % degrees of freedom = 2^mmin - 1
        obj.uncert = -tinv(obj.alpha/2, (2^obj.mmin) - 1);
      else
        obj.uncert = -norminv(obj.alpha/2);
      end
      
      % apply periodization transformation to the function
      obj.ff = obj.doPeriodTx(obj.f, obj.ptransform);
      obj.gen_vec = obj.get_lattice_gen_vec(obj.dim);
      
      obj.mvec = obj.mmin:obj.mmax;
      length_mvec = length(obj.mvec);
      
      % to store debug info
      temp = cubBayesLattice_g.gpuArray_(zeros(length_mvec,1));
      obj.errorBdAll = temp;
      obj.muhatAll = temp;
      obj.aMLEAll = cubBayesLattice_g.gpuArray_(zeros(length_mvec,obj.dim));
      obj.lossMLEAll = temp;
      obj.timeAll = temp;
      obj.dscAll = temp;
      obj.s_All = temp;
      
    end
    
    % computes the integral
    function [muhat,out] = compInteg(obj)
      
      tstart = tic; %start the clock
      numM = length(obj.mvec);
      
      % pick a random value to apply as shift
      shift = rand(1,obj.dim);
      
      xun_=[];xpts_=[];ftilde_=[]; % temporary storage between iterations
      %% Iteratively find the number of points required for the cubature to meet
      % the error threshold
      for iter = 1:numM
        tstart_iter = tic;
        m = obj.mvec(iter);
        n = 2^m;
        
        %Update function values
        if obj.vdc_order
          [ftilde_,xun_,xpts_] = iter_fft_vdc(obj,iter,shift,xun_,xpts_,ftilde_);
        else
          [ftilde_,xun_,xpts_] = iter_fft(obj,iter,shift,xun_,xpts_,ftilde_);
        end
        [stop_flag, muhat] = stopping_criterion(obj, xun_, ftilde_, iter, m);
        
        obj.timeAll(iter) = toc(tstart_iter);  % store per iteration time
        
        % if stopAtTol true, exit the loop
        % else, run for for all 'n' values.
        % Used to compute error values for 'n' vs error plotting
        if obj.stopAtTol==true && stop_flag==true
          break
        end
      end
      out.n = n;
      out.time = toc(tstart);
      out.ErrBd = obj.errorBdAll(end);
      
      optParams.ErrBdAll = obj.errorBdAll;
      optParams.muhatAll = obj.muhatAll;
      optParams.mvec = obj.mvec;
      optParams.aMLEAll = obj.aMLEAll;
      optParams.timeAll = obj.timeAll;
      optParams.s_All = obj.s_All;
      optParams.dscAll = obj.dscAll;
      optParams.absTol = obj.absTol;
      optParams.relTol = obj.relTol;
      optParams.shift = shift;
      optParams.stopAtTol = obj.stopAtTol;
      out.optParams = optParams;
      if stop_flag==true
        out.exitflag = 1;
      else
        out.exitflag = 2;  % error tolerance may not be met
      end
      
      if stop_flag==false
        warning('GAIL:cubBayesLattice_g:maxreached',...
          ['In order to achieve the guaranteed accuracy, ', ...
          sprintf('used maximum allowed sample size %d. \n', n)] );
      end
      
      % convert from gpu memory to local
      muhat=obj.gather_(muhat);
      out=obj.gather_(out);
      
    end
    
    %% Efficient FFT computation algorithm, avoids recomputing the full fft
    function [ftilde_,xun_,xpts_] = iter_fft(obj,iter,shift,xun,xpts,ftildePrev)
      m = obj.mvec(iter);
      n = 2^m;
      
      % In every iteration except the first one, "n" number_of_points is doubled,
      % but FFT is only computed for the newly added points.
      % Previously computed FFT is reused.
      if iter == 1
        % In the first iteration compute full FFT
        xun_ = mod(bsxfun(@times,(0:1/n:1-1/n)',obj.gen_vec),1);
        xpts_ = mod(bsxfun(@plus,xun_,shift),1);  % shifted
        
        % Compute initial FFT
        ftilde_ = fft(objgpuArray_(obj.ff(xpts_))); %evaluate integrand's fft
      else
        xunnew = mod(bsxfun(@times,(1/n:2/n:1-1/n)',obj.gen_vec),1);
        xnew = mod(bsxfun(@plus,xunnew,shift),1);
        [xun_, xpts_] = obj.merge_pts(xun, xunnew, xpts, xnew, n, obj.dim);
        mnext=m-1;
        
        % Compute FFT on next set of new points
        ftildeNextNew = fft(obj.gpuArray_(obj.ff(xnew)));
        if obj.debugEnable
          cubBayesLattice_g.alertMsg(ftildeNextNew, 'Nan', 'Inf');
        end
        
        % combine the previous batch and new batch to get FFT on all points
        ftilde_ = obj.merge_fft(ftildePrev, ftildeNextNew, mnext);
      end
    end
    
    % Lattice points are ordered in van der Corput sequence, so we cannot use
    % Matlab's built-in fft routine. We use a custom one instead.
    function [ftilde_,xun_,xpts_] = iter_fft_vdc(obj,iter,shift,xun,xpts,ftildePrev)
      m = obj.mvec(iter);
      n = 2^m;
      
      % In every iteration except the first one, "n" number_of_points is doubled,
      % but FFT is only computed for the newly added points.
      % Previously computed FFT is reused.
      if iter == 1
        % in the first iteration compute the full FFT
        [xpts_,xun_] = obj.simple_lattice_gen(n,obj.dim,shift,true);
        
        % Compute initial FFT
        ftilde_ = obj.fft_DIT(obj.gpuArray_(obj.ff(xpts_)),m); %evaluate integrand's fft
      else
        [xnew,xunnew] = obj.simple_lattice_gen(n,obj.dim,shift,false);
        mnext=m-1;
        
        % Compute FFT on next set of new points
        ftildeNextNew = obj.fft_DIT(obj.gpuArray_(obj.ff(xnew)),mnext);
        if obj.debugEnable
          cubBayesLattice_g.alertMsg(ftildeNextNew, 'Nan', 'Inf');
        end
        
        xpts_ = [xpts; xnew];
        temp = zeros(n,obj.dim);
        temp(1:2:n-1,:) = xun;
        temp(2:2:n,:) = xunnew;
        xun_ = temp;
        % combine the previous batch and new batch to get FFT on all points
        ftilde_ = obj.merge_fft(ftildePrev, ftildeNextNew, mnext);
      end
    end
    
    % decides if the user-defined error threshold is met
    function [success,muhat] = stopping_criterion(obj, xpts, ftilde, iter, m)
      
      tstart=tic;
      n=2^m;
      success = false;
      % search for optimal shape parameter
      if obj.kernType==2
        % lnaRange = [-3,0]; % \theta \in [0, \inf]
        % lnbRange = [-5,5]; % b \in [0, 1]
        if 1
          % unconstrained search on two variables.
          % unstable, fails some times
          options = optimset('TolX',1e-2);  %,'PlotFcns',@optimplotfval);
          fLoss = @(x)ObjectiveFunctionFmin(obj,exp(x(1)),1.0/(1+exp(-x(2))),xpts,ftilde);
          aOPT = fminsearch(fLoss, [0,0], options);
          thetaOpt = exp(aOPT(1));
          bOpt = 1.0/(1+exp(-aOPT(2)));
          [loss,Lambda,Lambda_ring,RKHSnorm] = ObjectiveFunctionFmin(obj, ...
            thetaOpt,bOpt,xpts,ftilde);
        else
          lnaMLE = fminsearch(@(lna) ...
            ObjectiveFunction(obj, exp(lna),xpts,ftilde), ...
            0,optimset('TolX',1e-2));
          thetaOpt = exp(lnaMLE);
          [loss,Lambda,Lambda_ring,RKHSnorm] = ObjectiveFunction(obj, thetaOpt,xpts,ftilde);
        end
      else
        if 1
          % Gradient descent to find opt shape param
          thetaOpt = fmin_adam(...
            @(phi)dObjectiveFunction(obj, phi,xpts,ftilde), ...
                ones(1,obj.dim), 0.01);
          [loss,Lambda,Lambda_ring,RKHSnorm] = ObjectiveFunction(obj, ...
            thetaOpt,xpts,ftilde);

          if 0
            % parameter optimization using steepest descent
            lnaRange = -5:0.1:5;
            lossD = zeros(1, length(lnaRange));
            lossMLE = zeros(1, length(lnaRange));
            lossMLE_ = zeros(1, length(lnaRange));
            trace_part = zeros(1, length(lnaRange));
            deriv_part_num = zeros(1, length(lnaRange));
            deriv_part_den = zeros(1, length(lnaRange));
            loss1 = zeros(1, length(lnaRange));
            for j=1:length(lnaRange)
              a = exp(lnaRange(j));
              % , Lambda,trace_part(j),deriv_part_num(j),deriv_part_den(j),loss1(j)
              [lossMLE_(j),lossD(j)] = dObjectiveFunction(obj,a,xpts,ftilde);
              [lossMLE(j)] = ObjectiveFunction(obj, a,xpts,ftilde);
            end
          end
          
          if 0
            % simple steepses descent
            lntheta = 2;
            maxiter = 1000;
            lnthetaVec = zeros(1, maxiter); 
            for iter=1:maxiter
              theta = exp(lntheta);
              [~, grad] = dObjectiveFunction(obj,theta,xpts,ftilde);
              lntheta = lntheta - 0.1*grad;
              lnthetaVec(iter) = lntheta;
            end
            figure; plot(lnthetaVec)
          end

          if 0
            figure(123)
            semilogy(lnaRange, (trace_part), lnaRange, (loss1 - min(loss1)))
            legend({'trace','loss1'},'Location','best')
            
            figure(124)
            semilogy(lnaRange, abs(trace_part), lnaRange, deriv_part_num, ...
              lnaRange, deriv_part_den)
            legend({'trace','num','den'},'Location','best')
            
            figure(125)
            semilogy(lnaRange, abs(trace_part), lnaRange, deriv_part_num, ...
              lnaRange, deriv_part_den, lnaRange, deriv_part_num./deriv_part_den)
            legend({'trace','num','den','deriv'},'Location','best')
          end
          
          if 0
            figure(126)
            % Compare MLE loss vs derivative
            % semilogy(lnaRange, (lossD - min(lossD)+1), lnaRange, (lossMLE - min(lossMLE)+1))
            % legend({'lossD', 'lossMLE'},'Location','best')
            
            figure(127)
            % Compare MLE loss vs derivative
            plot(lnaRange, (lossD), lnaRange, (lossMLE))
            legend({'lossD', 'lossMLE'},'Location','best')
          end
          
          fprintf('');
        else
          if 1
            % bounded search
            lnaRange = [-5,5];
            lnaMLE = fminbnd(@(lna) ...
              ObjectiveFunction(obj, exp(lna),xpts,ftilde), ...
              lnaRange(1),lnaRange(2),optimset('TolX',1e-2));
            thetaOpt = exp(lnaMLE);
            [loss,Lambda,Lambda_ring,RKHSnorm] = ObjectiveFunction(obj, thetaOpt,xpts,ftilde);
          else
            lnaMLE = fminsearch(@(lna) ...
              ObjectiveFunction(obj, exp(lna),xpts,ftilde), ...
              0,optimset('TolX',1e-2));
            thetaOpt = exp(lnaMLE);
            [loss,Lambda,Lambda_ring,RKHSnorm] = ObjectiveFunction(obj, thetaOpt,xpts,ftilde);
          end
        end
      end
      
      %Check error criterion
      % compute DSC
      if obj.fullBayes==true
        % full bayes
        if obj.avoidCancelError
          DSC = abs(Lambda_ring(1)/n);
        else
          DSC = abs((Lambda(1)/n) - 1);
        end
        % 1-alpha two sided confidence interval
        ErrBd = obj.uncert*sqrt(DSC * RKHSnorm/(n-1));
      elseif obj.GCV==true
        % GCV based stopping criterion
        if obj.avoidCancelError
          DSC = abs(Lambda_ring(1)/(n + Lambda_ring(1)));
        else
          DSC = abs(1 - (n/Lambda(1)));
        end
        temp = Lambda;
        temp(1) = n + Lambda_ring(1);
        C_Inv_trace = sum(1./temp(temp~=0));
        ErrBd = obj.uncert*sqrt(DSC * (RKHSnorm) /C_Inv_trace);
      else
        % empirical bayes
        if obj.avoidCancelError
          DSC = abs(Lambda_ring(1)/(n + Lambda_ring(1)));
        else
          DSC = abs(1 - (n/Lambda(1)));
        end
        ErrBd = obj.uncert*sqrt(DSC * RKHSnorm/n);
      end
      
      if obj.arbMean==true % zero mean case
        muhat = ftilde(1)/n;
      else % non zero mean case
        muhat = ftilde(1)/Lambda(1);
      end
      muminus = muhat - ErrBd;
      muplus = muhat + ErrBd;
      
      % store intermediate values for post analysis
      % store the debug information
      obj.dscAll(iter) = sqrt(DSC);
      obj.s_All(iter) = sqrt(RKHSnorm/n);
      obj.muhatAll(iter) = muhat;
      obj.errorBdAll(iter) = ErrBd;
      obj.aMLEAll(iter, :) = thetaOpt;
      obj.lossMLEAll(iter) = loss;
      
      if obj.gaussianCheckEnable == true
        % plots the transformed and scaled integrand values as normal plot
        % Useful to verify the assumption, integrand was an instance of a Gaussian process
        CheckGaussianDensity(obj, ftilde, Lambda)
      end
      t_end=toc(tstart);

      fprintf('thetaOpt=%s, n=%d, ErrBd=%1.2e, time=%1.2e, absTol=%1.2e\n', ...
        mat2str(thetaOpt, 3), n, ErrBd, t_end, obj.absTol);
      
      if 2*ErrBd <= ...
          max(obj.absTol,obj.relTol*abs(muminus)) + max(obj.absTol,obj.relTol*abs(muplus))
        if obj.errorBdAll(iter)==0
          obj.errorBdAll(iter) = eps;
        end
        % stopping criterion achieved
        success = true;
      end
      
    end
    
    % objective function to estimate parameter theta
    % MLE : Maximum likelihood estimation
    % GCV : Generalized cross validation
    % function [loss,Lambda,Lambda_ring,RKHSnorm] = ObjectiveFunctionFmin(obj,a,b,xun,ftilde)
    function [loss,Lambda,Lambda_ring,RKHSnorm] = ObjectiveFunction(obj,a,xun,ftilde)
      
      n = length(ftilde);
      %[Lambda, Lambda_ring] = obj.kernel(xun,b,a,obj.avoidCancelError,obj.kernType, obj.debugEnable);
      [Lambda, Lambda_ring] = obj.kernel(xun,obj.order,a,obj.avoidCancelError, ...
                              obj.kernType,obj.debugEnable);
      
      % compute RKHSnorm
       temp = abs(ftilde(Lambda~=0).^2)./(Lambda(Lambda~=0)) ;
      
      % compute loss
      if obj.GCV==true
        % GCV
        temp_gcv = abs(ftilde(Lambda~=0)./(Lambda(Lambda~=0))).^2 ;
        loss1 = 2*log(sum(1./Lambda(Lambda~=0)));
        loss2 = log(sum(temp_gcv(2:end)));
        % ignore all zero eigenvalues
        loss = loss2 - loss1;
        
        if obj.arbMean==true
          RKHSnorm = sum(temp_gcv(2:end))/n;
        else
          RKHSnorm = sum(temp_gcv)/n;
        end
      else
        % default: MLE
        if obj.arbMean==true
          RKHSnorm = sum(temp(2:end))/n;
          temp_1 = sum(temp(2:end));
        else
          RKHSnorm = sum(temp)/n;
          temp_1 = sum(temp);
        end
        
        % ignore all zero eigenvalues
        loss1 = sum(log(Lambda(Lambda~=0)));
        loss2 = n*log(temp_1);
        loss = (loss1 + loss2)/n;
      end
      
      if obj.debugEnable
        cubMLESobol.alertMsg(RKHSnorm, 'Imag');
        cubMLESobol.alertMsg(loss1, 'Inf');
        cubMLESobol.alertMsg(loss2, 'Inf');
        cubMLESobol.alertMsg(loss, 'Inf', 'Imag', 'Nan');
        cubMLESobol.alertMsg(Lambda, 'Imag');
      end
    end
    
    % ,Lambda,trace_part,deriv_part_num,deriv_part_den, loss1
    % computes Gradient of the objective function
    function [lossObj,lossD] = dObjectiveFunction(obj,a,xun,ftilde)
      
      if length(a) > 1
        if size(a,1) > size(a,2)
          a = a';  % we need row vector
        end
      end
      n = length(ftilde);
      [dLambda, Lambda] = obj.dKernel(xun,obj.order,a,obj.avoidCancelError, ...
        obj.kernType,obj.debugEnable);
      
%       [Lambda, Lambda_ring] = obj.kernel(xun,obj.order,a,obj.avoidCancelError, ...
%         obj.kernType,obj.debugEnable);
%       if abs(sum(Lambda_-Lambda)) > 1E-5
%         fprintf('')
%       end

      % ignore all zero eigenvalues
      if obj.GCV==true
        % GCV
        temp_gcv = abs(ftilde(Lambda~=0)./(Lambda(Lambda~=0))).^2 ;
        % error("Not implemented")
        deriv_part_num = abs(...
          bsxfun(@times, ...
          (ftilde(Lambda~=0).^2)./(Lambda(Lambda~=0).^3), dLambda(Lambda~=0, :)));
        if obj.arbMean==true
          deriv_part_num = sum(deriv_part_num(2:end, :), 1);
          deriv_part_den = sum(temp_gcv(2:end));
        else
          deriv_part_num = sum(deriv_part_num(1:end, :), 1);
          deriv_part_den = sum(temp_gcv);
        end
        deriv_part = deriv_part_num/deriv_part_den;
        det_part_num = sum(...
          bsxfun(@times, ...
          dLambda(Lambda~=0, :), (Lambda(Lambda~=0).^2)), 1);
        det_part = det_part_num/sum(1./Lambda(Lambda~=0));
        lossD = -deriv_part - det_part;
        lossGCV = log(deriv_part_den) - 2*log(sum(1./Lambda(Lambda~=0)));
        lossObj = lossGCV;
      else
        % trace_part = sum(dLambda(Lambda~=0)./Lambda(Lambda~=0))/n;
        trace_part = sum(bsxfun(@rdivide, dLambda(Lambda~=0,:), Lambda(Lambda~=0)), 1)/n;

        % default: MLE
        temp = abs(ftilde(Lambda~=0).^2)./(Lambda(Lambda~=0)) ;
        % deriv_part_num = abs((ftilde(Lambda~=0).^2).*dLambda(Lambda~=0))./(Lambda(Lambda~=0).^2);
        deriv_part_num = abs(...
          bsxfun(@times, ...
          (ftilde(Lambda~=0).^2)./(Lambda(Lambda~=0).^2), dLambda(Lambda~=0, :)));
        if obj.arbMean==true
          deriv_part_num = sum(deriv_part_num(2:end, :), 1);
          deriv_part_den = sum(temp(2:end));
        else
          deriv_part_num = sum(deriv_part_num(1:end, :), 1);
          deriv_part_den = sum(temp);
        end

        deriv_part = deriv_part_num/deriv_part_den;
        lossD = trace_part - deriv_part;
        lossDet = sum(log(Lambda(Lambda~=0)))/n;
        lossMLE = lossDet + log(deriv_part_den);
        lossObj = lossMLE;
      end

    end
        
    % Plots the transformed and scaled integrand values as normal plots.
    % This is to verify the assumption, integrand was an instance of
    % gaussian process.
    % Normally distributed :
    %    https://www.itl.nist.gov/div898/handbook/eda/section3/normprp1.htm
    % Short Tails :
    %   .../normprp2.htm
    % Long Tails :
    %    .../normprp3.htm
    function [hFig, plotFileName] = CheckGaussianDensity(obj, ftilde, lambda)
      n = length(ftilde);
      ftilde(1) = 0;  % substract by (m_\MLE \vone) to get zero mean
      % 'y' is real, so ifft(fft(real)) is 'real'
      w_ftilde = real(ifft((ftilde)./sqrt(lambda)));
      % w_ftilde = ((abs(ftilde)./sqrt(lambda)));
      % w_ftilde = real(ifft((ftilde.^2)./(lambda)));
      
      if obj.visiblePlot, hFig=figure();
      else, hFig = figure('visible','off'); end
      
      set(hFig,'defaultaxesfontsize',16, ...
        'defaulttextfontsize',16, ... %make font larger
        'defaultLineLineWidth',0.75, 'defaultLineMarkerSize',8)
      
      % Shapiro-Wilk test, 
      % Ex:
      %   random normal  [H_,pValue_,W_] = swtest(randn(1024,1))
      %   random uniform [H_,pValue_,W_] = swtest(rand(1024,1))
      [H, pValue, W] = swtest(w_ftilde);
      
      if H==1, Hval='false'; else, Hval='true'; end
      fprintf('Shapiro-Wilk test: Normal=%s, pValue=%1.3e, W=%1.3f, n=%d\n', ...
        Hval, pValue, W, n);
      
      % other option : qqplot(w_ftilde)
      normplot(w_ftilde)
      set(hFig, 'units', 'inches', 'Position', [1 1 8 6])
      
      title(sprintf('Normplot %s n=%d Tx=%s', obj.fName, n, obj.ptransform))
      % figure(); hist(w_ftilde);
      
      % build filename with path to store the plot
      plotFileName = sprintf('%s%s Normplot d_%d order_%d Period_%s n_%d.png',...
         obj.figSavePath, obj.fName, obj.dim, obj.order, obj.ptransform, n);
      % plotFileName
      % saveas(hFig, plotFileName)
    end
    
    % parses each input argument passed and assigns to obj.
    % Warns any unsupported options passed
    function parse_input_args(obj, varargin)
      if nargin > 0
        iStart = 1;
        if isa(varargin{1},'cubBayesLattice_g')
          iStart = 2;
        end
        % parse each input argument passed
        if nargin >= iStart
          wh = find(strcmp(varargin(iStart:end),'f'));
          if ~isempty(wh), obj.f = varargin{wh+iStart}; else, obj.warn_fd(); end
          wh = find(strcmp(varargin(iStart:end),'dim'));
          if ~isempty(wh), obj.dim = varargin{wh+iStart}; else, obj.warn_fd; end
          wh = find(strcmp(varargin(iStart:end),'absTol'));
          if ~isempty(wh), obj.absTol = varargin{wh+iStart}; end
          wh = find(strcmp(varargin(iStart:end),'relTol'));
          if ~isempty(wh), obj.relTol = varargin{wh+iStart}; end
          wh = find(strcmp(varargin(iStart:end),'order'));
          if ~isempty(wh), obj.order = varargin{wh+iStart}; end
          wh = find(strcmp(varargin(iStart:end),'ptransform'));
          if ~isempty(wh), obj.ptransform = varargin{wh+iStart}; end
          wh = find(strcmp(varargin(iStart:end),'arbMean'));
          if ~isempty(wh), obj.arbMean = varargin{wh+iStart}; end
          wh = find(strcmp(varargin(iStart:end),'stopAtTol'));
          if ~isempty(wh), obj.stopAtTol = varargin{wh+iStart}; end
          wh = find(strcmp(varargin(iStart:end),'figSavePath'));
          if ~isempty(wh), obj.figSavePath = varargin{wh+iStart}; end
          wh = find(strcmp(varargin(iStart:end),'fName'));
          if ~isempty(wh), obj.fName = varargin{wh+iStart}; end
          wh = find(strcmp(varargin(iStart:end),'stopCriterion'));
          if ~isempty(wh), obj.stopCriterion = varargin{wh+iStart}; end
          wh = find(strcmp(varargin(iStart:end),'alpha'));
          if ~isempty(wh), obj.alpha = varargin{wh+iStart}; end
        end
      end
      
      function validate_input_args(obj)
        if ~gail.isfcn(obj.f)
          warning('GAIL:cubBayesLattice_g:fnotfcn',...
            'The given input f should be a function handle.\n' );
        end
        
        if obj.kernType==1
          if ~(obj.order==1 || obj.order==2)
            warning('GAIL:cubBayesLattice_g:r_invalid',...
              'Kernel order, r=%d, is not supported; it must be 1 or 2. The algorithm is using default value r=2.\n', ...
              obj.order);
            obj.order = 1;
          end
        elseif obj.kernType==2
          if ~(obj.order>0 && obj.order<1)
            warning('GAIL:cubBayesLattice_g:r_invalid',...
              'Kernel order, r=%1.1f invalid, must be in (0, 1), using default r=0.4\n', ...
              obj.order);
            obj.order = 0.4;
          end
        end
        
        stopCriterions = {'full','GCV','MLE'};
        if ~ismember(obj.stopCriterion, stopCriterions)
          str_stopCriterions = strjoin(stopCriterions, ', ');
          warning('GAIL:cubBayesLattice_g:stop_crit_invalid',...
            'Stop criterion = "%s" is not supported; it must be from "%s". The algorithm is using default value "MLE".\n', ...
            obj.stopCriterion, str_stopCriterions);
          obj.stopCriterion = 'MLE';
        end
        
        var_txs = {'Baker','C0','C1','C1sin','C2sin','C3sin','none'};
        if ~ismember(obj.ptransform, var_txs)
          str_var_txs = strjoin(var_txs, ', ');
          warning('GAIL:cubBayesLattice_g:var_transform_invalid',...
            'Periodizing transform = "%s" is not supported; the value must be from "%s". The algorithm is using default value "Baker".\n', ...
            obj.ptransform, str_var_txs);
          obj.ptransform = 'Baker';
        end
      end
      
      validate_input_args(obj);
    end

    
    % plots the objective for the MLE of theta, useful for diagnozing any
    % issues with the code
    function [minTheta, hFigCost, hFigNormVec] = plotObjectiveFunc(obj)
      
      obj.visiblePlot= true;
      
      numM = length(obj.mvec);
%       n = 2.^obj.mvec(end);
      shift = rand(1,obj.dim);

%       [xpts, xptsun] = cubBayesLattice_g.simple_lattice_gen(n,obj.dim,shift,true);
%       fx = obj.ff(xpts);  % Note: periodization transform already applied
        
      %% plot ObjectiveFunction
      lnTheta = -5:0.2:5;
%       % build filename with path to store the plot
%       plotFileName = sprintf('%s%s_Cost_d%d_r%d_%s_%s.png',...
%         obj.figSavePath, obj.fName, obj.dim, obj.order, obj.ptransform, obj.stopCriterion);
      
      costMLE = zeros(numM,numel(lnTheta));
      tstart = tic;
      
      % loop over all the m values
      for iter = 1:numM
        nii = 2^obj.mvec(iter);
        
        eigvalK = zeros(numel(lnTheta),nii);
        % ftilde_iter = fft(bitrevorder(fx(1:nii))); %/nii;
        
        % [xlat,xpts_un,xlat_un,xpts]
        % br_xun = bitrevorder(xpts(1:nii,:));
        % br_xun = xptsun(1:nii,:);
        [xlat, xpts_un, ~, xpts] = cubBayesLattice_g.simple_lattice_gen(nii,obj.dim,shift,true);
        ftilde_iter = fft(obj.ff(xpts_un));
        
        tic
        %par
        for k=1:numel(lnTheta)
          [costMLE(iter,k),eigvalK(k,:)] = ObjectiveFunction(obj, exp(lnTheta(k)),...
            xpts_un,(ftilde_iter));
        end
        toc
        
        % Gaussian diagnosis for n < 8194, swtest does not work bigger 'n'
        % values
        if nii < (2^13)
          [minVal,Index] = min(real(costMLE(iter,:)));
          minTheta = exp(lnTheta(Index));
          % if Index==numel(lnTheta)
            Index = find(lnTheta==0);
          % end

          lambda = eigvalK(Index,:)';
          % figure(); loglog(sort(lambda, 'descend'), 'o', 'MarkerSize',2);
          % figure(); loglog(lambda, 'o', 'MarkerSize',2);
          if any(lambda <=0)
            warning('lambda cannot be zero or negative')
          end
          [hFigNorm, fileName] = CheckGaussianDensity(obj, (ftilde_iter), lambda);
          hFigNormVec{iter} = {hFigNorm, fileName};
        end
      end
      
      toc(tstart)
      
      if obj.visiblePlot==false
        hFigCost = figure('visible','off');
      else
        hFigCost = figure();
      end
      
      % semilogx
      semilogx(exp(lnTheta),real(costMLE));
      set(hFigCost, 'units', 'inches', 'Position', [0 0 14 9])
      xlabel('Shape param, \(\theta\)')
      ylabel('MLE Cost, \( \log \frac{y^T K_\theta^{-1}y}{[\det(K_\theta^{-1})]^{1/n}} \)')
      axis tight;
      if obj.arbMean
        mType = '\(m \neq 0\)'; % arb mean
      else
        mType = '\(m = 0\)'; % zero mean
      end
      title(sprintf('%s d=%d r=%d Tx=%s %s', obj.fName, obj.dim, obj.order, obj.ptransform, mType));
      [minVal,Index] = min(real(costMLE),[],2);
      
      % mark the min theta values found using fminbnd
      minTheta = exp(lnTheta(Index));
      hold on;
      semilogx(minTheta, minVal, '.');
      if exist('aMLEAll', 'var')
        semilogx(obj.aMLEAll, obj.lossMLEAll, '+');
      end
      temp = string(obj.mvec);
      temp = strcat('\(2^{',temp,'}\)');
      temp(end+1) = '\(\theta_{min_{true}}\)';
      if exist('aMLEAll', 'var')
        temp(end+1) = '\(\theta_{min_{est}}\)';
      end
      legend(temp,'location','best'); axis tight
      % saveas(hFigCost, plotFileName)
    end    
    
  end
  
  methods(Static)
    % prints debug message if the given variable is Inf, Nan or
    % complex, etc
    % Example: alertMsg(x, 'Inf', 'Imag')
    %          prints if variable 'x' is either Infinite or Imaginary
    function alertMsg(varargin)
      %varname = @(x) inputname(1);
      if nargin > 1
        iStart = 1;
        varTocheck = varargin{iStart};
        iStart = iStart + 1;
        inpvarname = inputname(1);
        
        while iStart <= nargin
          type = varargin{iStart};
          iStart = iStart + 1;
          
          switch type
            case 'Nan'
              if any(isnan(varTocheck))
                warning('%s has NaN values', inpvarname);
              end
            case 'Inf'
              if any(isinf(varTocheck))
                warning('%s has Inf values', inpvarname);
              end
            case 'Imag'
              if ~all(isreal(varTocheck))
                warning('%s has complex values', inpvarname)
              end
            otherwise
              warning('%s : unknown type check requested !', inpvarname)
          end
        end
      end
      
    end
    
    % Computes modified kernel Km1 = K - 1
    % Useful to avoid cancellation error in the computation of (1 - n/\lambda_1)
    function [Km1, K] = kernel_t(aconst, Bern)
      d = size(Bern, 2);
      if length(aconst) == 1
        theta = ones(1,d)*aconst;
      else
        theta = aconst;
      end
      
      Kjm1 = theta(1)*Bern(:,1);  % Kernel at j-dim minus One
      Kj = 1 + Kjm1;  % Kernel at j-dim
      
      for j=2:d
        Kjm1_prev = Kjm1; Kj_prev = Kj;  % save the Kernel at the prev dim
        
        Kjm1 = theta(j)*Bern(:,j).*Kj_prev + Kjm1_prev;
        Kj = 1 + Kjm1;
      end
      
      Km1 = Kjm1; K = Kj;
    end
    
    % Truncated Bernoulli polynomial series expansion
    function fval = bernoulli_series(xpts,b_order)
      % Eqn. 24.8.1 from https://dlmf.nist.gov/24.8
      const = -(-1)^(b_order/2)*2*factorial(b_order)/((2*pi)^b_order);
      N = 2^10;
      kvec = (1:N)';
      argx = @(x) 2*pi*bsxfun(@times, kvec, x);
      c_r = @(x)cos(argx(x))./(kvec.^2);
      f_ran = @(x) const*(( sum(c_r(x) ))) ;
      [n,d]=size(xpts);
      A = reshape(xpts, 1,n,d);  % add extra dimension for the series sum
      fval = f_ran(A);
      fval = reshape(fval, n,d);  % remove extra dimension
      %   fval=zeros(n,d);
      %   for i=1:n
      %     fval(i,:) = f_ran(xpts(i,:));
      %   end
    end
    
    % derivative of the kernel w.r.t. shape parameter
    function [dLambda, Lambda] = dKernel(xun,order,a,avoidCancelError,...
        kernType,debugEnable)
      
      if kernType==1
        b_order = order*2; % Bernoulli polynomial order as per the equation
        constMult = -(-1)^(b_order/2)*((2*pi)^b_order)/factorial(b_order);
        % constMult = -(-1)^(b_order/2);
        if b_order == 2
          bernPoly = @(x)(-x.*(1-x) + 1/6);
          % bernPoly = @(x) cubBayesLattice_g.bernoulli_series(x,b_order);
        elseif b_order == 4
          bernPoly = @(x)( ( (x.*(1-x)).^2 ) - 1/30);
        else
          error('Bernoulli order not implemented !');
        end
        kernelFunc = @(x) bernPoly(x);
      else
        b = order;
        kernelFunc = @(x) 2*b*((cos(2*pi*x)-b))./(1 + b^2 - 2*b*cos(2*pi*x));
        constMult = 1;
      end
      
      [~, dim] = size(xun);
      if avoidCancelError
        temp = kernelFunc(xun);
        % Computes C1m1 = C1 - 1
        % C1_new = 1 + C1m1 indirectly computed in the process
        [C1m1] = cubBayesLattice_g.kernel_t(a*constMult, temp);
        % eigenvalues must be real : Symmetric pos definite Kernel
        
        if length(a) > 1
          % different theta per dimension
          try
            partb = 1 - 1./(1+bsxfun(@times,a*constMult,temp));
          catch mErr
            error('*** cubBayesLattice_g: Error when evaluating partb.');
          end
          % dC1 = (1./a)*(1 + C1m1).*partb;
          dC1 = bsxfun(@times, (1./a), ...
            bsxfun(@times, (1 + C1m1), partb));
        else
          % common theta
          partb = -(1/dim)*sum(1./(1+a*constMult*temp), 2);
          dC1 = (dim/a)*(1 + C1m1 + partb + C1m1.*partb);
        end
        dLambda = real(fft(dC1));
        Lambda = real(fft(1 + C1m1));
        
      else
        % direct approach to compute first row of the kernel Gram matrix
        temp_ = bsxfun(@times, (a)*constMult, kernelFunc(xun));
        C1 = prod(1 + temp_, 2);
        dC1 = (dim/a)*C1.*(1 - (1/dim)*sum(1./(1+temp_), 2));
        
        % matlab's builtin fft is much faster and accurate
        % eigenvalues must be real : Symmetric pos definite Kernel
        dLambda = real(fft(dC1));
        Lambda = real(fft(C1));
      end
      
    end
    
    % Shift invariant kernel
    % C1 : first row of the covariance matrix
    % a : kernel's shape parameter
    % Lambda : eigenvalues of the covariance matrix
    % Lambda_ring = fft(C1 - 1)
    function [Lambda, Lambda_ring] = kernel(xun,order,a,avoidCancelError,...
        kernType,debugEnable)
      
      if kernType==1
        b_order = order*2; % Bernoulli polynomial order as per the equation
        constMult = -(-1)^(b_order/2)*((2*pi)^b_order)/factorial(b_order);
        % constMult = -(-1)^(b_order/2);
        if b_order == 2
          bernPoly = @(x)(-x.*(1-x) + 1/6);
          % bernPoly = @(x) cubBayesLattice_g.bernoulli_series(x,b_order);
        elseif b_order == 4
          bernPoly = @(x)( ( (x.*(1-x)).^2 ) - 1/30);
        else
          error('Bernoulli order not implemented !');
        end
        kernelFunc = @(x) bernPoly(x);
      else
        b = order;
        kernelFunc = @(x) 2*b*((cos(2*pi*x)-b))./(1 + b^2 - 2*b*cos(2*pi*x));
        constMult = 1;
      end
      
      if avoidCancelError
        % Computes C1m1 = C1 - 1
        % C1_new = 1 + C1m1 indirectly computed in the process
        [C1m1, C1_alt] = cubBayesLattice_g.kernel_t(a*constMult, kernelFunc(xun));
        % eigenvalues must be real : Symmetric pos definite Kernel
        Lambda_ring = real(fft(C1m1));
        
        Lambda = Lambda_ring;
        Lambda(1) = Lambda_ring(1) + length(Lambda_ring);
        % C1 = prod(1 + (a)*constMult*bernPoly(xun),2);  % direct computation
        % Lambda = real(fft(C1));
        
        if debugEnable == true
          % eigenvalues must be real : Symmetric pos definite Kernel
          Lambda_direct = real(fft(C1_alt)); % Note: fft output unnormalized
          if sum(abs(Lambda_direct-Lambda)) > 1
            fprintf('Possible error: check Lambda_ring computation')
          end
        end
      else
        % direct approach to compute first row of the kernel Gram matrix
        C1 = prod(1 + bsxfun(@times, (a)*constMult, kernelFunc(xun)),2);
        % matlab's builtin fft is much faster and accurate
        % eigenvalues must be real : Symmetric pos definite Kernel
        Lambda = real(fft(C1));
        Lambda_ring = 0;
      end
      
    end
    
    % computes the periodization transform for the given function values
    function f = doPeriodTx(fInput, ptransform)
      
      if strcmp(ptransform,'Baker')
        f=@(x) fInput(1-2*abs(x-1/2)); % Baker's transform
      elseif strcmp(ptransform,'C0')
        f=@(x) fInput(3*x.^2-2*x.^3).*prod(6*x.*(1-x),2); % C^0 transform
      elseif strcmp(ptransform,'C1')
        % C^1 transform
        f=@(x) fInput(x.^3.*(10-15*x+6*x.^2)).*prod(30*x.^2.*(1-x).^2,2);
      elseif strcmp(ptransform,'C1sin')
        % Sidi C^1 transform
        f=@(x) fInput(x-sin(2*pi*x)/(2*pi)).*prod(2*sin(pi*x).^2,2);
      elseif strcmp(ptransform,'C2sin')
        % Sidi C^2 transform
        psi3 = @(t) (8-9*cos(pi*t)+cos(3*pi*t))/16;
        psi3_1 = @(t) (9*sin(pi*t)*pi- sin(3*pi*t)*3*pi)/16;
        f=@(x) fInput(psi3(x)).*prod(psi3_1(x),2);
      elseif strcmp(ptransform,'C3sin')
        % Sidi C^3 transform
        psi4 = @(t) (12*pi*t-8*sin(2*pi*t)+sin(4*pi*t))/(12*pi);
        psi4_1 = @(t) (12*pi-8*cos(2*pi*t)*2*pi+sin(4*pi*t)*4*pi)/(12*pi);
        f=@(x) fInput(psi4(x)).*prod(psi4_1(x),2);
      elseif strcmp(ptransform,'none')
        % do nothing
        f=@(x) fInput(x);
      else
        error('Error: Periodization transform %s not implemented', ptransform);
      end
      
    end
    
    % just returns the generator for rank-1 Lattice point generation
    function [z] = get_lattice_gen_vec(d)
      z = [1, 433461, 315689, 441789, 501101, 146355, 88411, 215837, 273599 ...
        151719, 258185, 357967, 96407, 203741, 211709, 135719, 100779, ...
        85729, 14597, 94813, 422013, 484367]; %generator
      z = z(1:d);
    end
    
    % generates rank-1 Lattice points in van der Corput sequence order
    function [xlat,xpts_un,xlat_un,xpts] = simple_lattice_gen(n,d,shift,firstBatch)
      z = cubBayesLattice_g.get_lattice_gen_vec(d);
      
      nmax = n;
      nmin = 1 + n/2;
      if firstBatch==true
        nmin = 1;
      end
      nelem=nmax-nmin+1;
      
      if firstBatch==true
        brIndices=cubBayesLattice_g.vdc(nelem)';
        xpts_un=mod(bsxfun(@times,(0:1/n:1-1/n)',z),1); % unshifted in direct order
      else
        brIndices=cubBayesLattice_g.vdc(nelem)'+1/(2*(nmin-1));
        xpts_un=mod(bsxfun(@times,(1/n:2/n:1-1/n)',z),1); % unshifted in direct order

      end
      xpts = mod(bsxfun(@plus,xpts_un,shift),1);  % shifted in direct order
      
      xlat_un = mod(bsxfun(@times,brIndices',z),1);  % unshifted
      xlat = mod(bsxfun(@plus,xlat_un,shift),1);  % shifted in VDC order
    end
    
    % van der Corput sequence in base 2
    function q = vdc(n)
      if n>1
        k=log2(n); % We compute the VDC seq part by part of power 2 size
        q=zeros(2^k,1);
        for l=0:k-1
          nl=2^l;
          kk=2^(k-l-1);
          ptind=repmat([false(nl,1);true(nl,1)],kk,1);
          q(ptind)=q(ptind)+1/2^(l+1);
        end
      else
        q=0;
      end
    end
    
    % fft with decimation in time i.e., input is already in 'bitrevorder'
    function y = fft_DIT(y,nmmin)
      for l=0:nmmin-1
        nl=2^l;
        nmminlm1=2^(nmmin-l-1);
        ptind=repmat([true(nl,1); false(nl,1)],nmminlm1,1);
        coef=exp(-2*pi()*sqrt(-1)*(0:nl-1)'/(2*nl));
        coefv=repmat(coef,nmminlm1,1);
        evenval=y(ptind);
        oddval=y(~ptind);
        y(ptind)=(evenval+coefv.*oddval);
        y(~ptind)=(evenval-coefv.*oddval);
      end
    end
    
    % using FFT butefly plot technique merges two halves of fft
    function ftildeNew = merge_fft(ftildeNew, ftildeNextNew, mnext)
      ftildeNew=[ftildeNew;ftildeNextNew];
      nl=2^mnext;
      ptind=[true(nl,1); false(nl,1)];
      coef=exp(-2*pi()*sqrt(-1)*(0:nl-1)'/(2*nl));
      coefv=repmat(coef,1,1);
      evenval=ftildeNew(ptind);
      oddval=ftildeNew(~ptind);
      ftildeNew(ptind)=(evenval+coefv.*oddval);
      ftildeNew(~ptind)=(evenval-coefv.*oddval);
    end
    
    % inserts newly generated points with the old set by interleaving them
    % xun - unshifted points
    function [xun, x] = merge_pts(xun, xunnew, x, xnew, n, d)
      temp = zeros(n,d);
      temp(1:2:n-1,:) = xun;
      temp(2:2:n,:) = xunnew;
      xun = temp;
      temp(1:2:n-1,:) = x;
      temp(2:2:n,:) = xnew;
      x = temp;
    end
    
    % to enable GPU for computations
    function y = gpuArray_(x)
      % y = gpuArray(x);  % use GPU
      y = x;  % use CPU
    end
    
    function y = gather_(x)
      % y = gather(x);  % use GPU
      y = x;  % use CPU
    end
    
    function warn_fd()
      warning('GAIL:cubBayesLattice_g:fdnotgiven',...
        'At least, function f and dimension need to be specified');
    end
  end
end

