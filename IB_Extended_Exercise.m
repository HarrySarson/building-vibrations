

% A matlab program to plot the theoretical response of the building in the
% 1A vibration lab.
% Based on code written by Penny Cox, now maintained by Aidan Reilly.
%  Tidied up by Jim Woodhouse October 2012
%
close all
clear ~ll

%  USER MUST SET TWO VALUES TO DETERMINE PLOT OPTIONS

if (exist('redoCalculations') == 0)
    redoCalculations = 1;
end

if (redoCalculations == 1)
    % Set value for plottype as follows:
    %       1 -> use 'ezplot' to plot a graph on normal axis (in rad/s)
    %       2 -> produce a semilog plot (in Hz)
    %       3 -> produce a graph on linear axis using 'plot' (in Hz)
    %       4 -> use 'fplot' to plot a graph on normal axis (in rad/s)
    %               better graph than 'ezplot' but slower
    plottype=1;

    % Set value to be positive to produce plots of the modeshapes
    modeshape_visualisation = 0;

    m = 1.83; % mass of one floor
    L = 0.2; % length
    N = 3; % number of degrees of freedom
    b = 0.08; % width
    E = 210E9; % Young's Modulus
    d = 0.001; % thickness
    I = b*d*d*d/12; % second moment of area
    kc = (24*E*I)/(L*L*L); % static stiffness for each floor

    M = m*eye(N); % create the mass matrix
    k = zeros(N,1);
    k = 1 + k; % set all spring constants to 1 (kc)

    K = zeros(N);
    for i=1:N   % Create the stiffness matrix
        for j=1:N
            if i==j
                if i < N
                    K(i,j) = k(i) + k(i+1);
                else
                    K(i,j) = k(i);
                end
            end
            if i-j == 1
                K(i,j) = -k(j);
            end
            if j-i == 1
                K(i,j) = -k(i);
            end
        end
    end

    K = K * kc;
    
    naturalFrequency = sqrt(kc/m);
    
    blank_row = zeros(1,N);
    blank_col = zeros(N,1);

    % To include vibration absorbers, you will need to modify
    %   the mass and stiffness matrices (above)

    [V,D] = eig(K,M);
    syms w;

    for imode=1:N
        freqs(imode) = sqrt(D(imode,imode));
    end

    %  Print natural frequencies and mode vectors in command window
    hertz = freqs/(2*pi)
    modeshapes = V

    B = K - ((w*w)*M);
    % harmonic solution for unit force at floor 1
    col = 1;1:N-1;
    disp = (inv(B))*[col];

    %start of ezplot section
    if (plottype == 1)
        hold on

        for ifloor = 1:N
            ezplot(disp(ifloor), [0, 130]);
            set(findobj('Type','line'),'Color','g');
        end

        set(findobj('Type','line'),'LineStyle','-')
    end

    %start of fplot section
    if (plottype == 4)
        hold on
        for ifloor = 1:N
            fplot(disp(ifloor), [0, 130]);
            set(findobj('Type','line'),'Color','g');
        end
        set(findobj('Type','line'),'LineStyle','-')
    end

    % Calculate frequency response functions
    all_disp = [];
    for w = 1:130;
        B = K - ((w*w)*M);
        % harmonic solution for unit force at floor 1
        disp = (inv(B))*[1;blank_col(2:N)];
        all_disp = [all_disp disp];
    end
    w = 1:130;

    % Log plot
    if (plottype == 2)
        semilogy((w./(2*pi)),abs(all_disp),'-');

        % Linear plot
    elseif (plottype == 3)
        plot((w./(2*pi)),(all_disp),'-');
    end

    % Plot modeshapes

    if (modeshape_visualisation > 0 )
        V = [blank_row; V];
        V_ = V + 0.25;
        V = V - 0.25;
        for imode=1:N
            figure
            axis([-5 5 0 (N+.5)])
            title1 = ['Mode ' int2str(imode) ': ' int2str(hertz(imode)) 'Hz'];
            title(title1)
            hold on
            plot((V(:,imode)),([0:N]))
            plot([0,blank_row],[0:N],'k')
            plot((V_(:,imode)),([0:N]))
            for jmode=1:N
                plot([V(jmode+1,imode) V_(jmode+1,imode)],[jmode jmode],'DisplayName',['Floor ' int2str(jmode)])
            end
        end
    end

    findconversions = 1;
    mPrime = zeros(N,N);
    kPrime = zeros(N,N);
    if (findconversions == 1)
        for mode = 1:N
            modeshape = modeshapes(:,mode);
            for floor = 1:N
                mPrime(floor,mode) = m * norm(modeshape)^2/(modeshape(floor)^2);
            end
            kPrime(:,mode) = mPrime(:,mode) * freqs(mode)^2;
        end
        mPrime
        kPrime
    end
end

sweep = 1;
lambdaSweep = 1;

lambdaMin = 0.01;
lambdaMax = 10;
lambdaLength = 100;

omegaMin = 15;
omegaMax = 28;
omegaLength = 100;

if (lambdaSweep == 1)
    floorLambdaMin = 0.01;
    floorLambdaMax = 50;
    floorLambdaLength = 100;
    lambdaFloor = linspace(floorLambdaMin, floorLambdaMax, floorLambdaLength);
else
    floorLambdaLength = 1;
    lambdaFloor = 2;
end


maxAmplitudes = zeros(lambdaLength, floorLambdaLength);

for sweepNumber = 1:floorLambdaLength
    lambdaPrime = lambdaFloor(sweepNumber) + zeros(N,N);
    if (sweep == 1)

        % Requires mPrime, kPrime, lambdaPrime,
        %          absorberMass, absorberStiffness
        %          lambdaRange, omegaRange           to be defined
        floor = 2;
        mode = 1;
        absorberMass = 0.1;
        absorberStiffness = absorberMass * freqs(mode)^2;
        F=[1;0];

        lambdaRange = logspace(log10(lambdaMin), log10(lambdaMax), lambdaLength);
        omegaRange  = logspace(log10(omegaMin),  log10(omegaMax),  omegaLength);

        M = [
          mPrime(floor,mode), 0;
          0, absorberMass;
        ];

        K = [
          kPrime(floor,mode) + absorberStiffness, -absorberStiffness;
          -absorberStiffness, absorberStiffness;
        ];

        maxAmpl = [
          0, NaN, NaN;
          0, NaN, NaN;
        ];

        for i = 1:lambdaLength

          absorberDamping = lambdaRange(i);

          Lambda = [
            lambdaPrime(floor, mode) + absorberDamping, -absorberDamping;
            -absorberDamping, absorberDamping;
          ];

          for j = 1:omegaLength

            w = omegaRange(j);

            X = inv(-w^2 * M + 1i * w * Lambda + K) * F;

            for k = 1:2
                Ampl(i, j, k) = X(k) * conj(X(k));
            end

          end
          maxAmplitudes(i, sweepNumber) = max(Ampl(i,:,1));
        end

        plotAllGraphs = 0;
        if (plotAllGraphs == 1)
            figure();
            surf(omegaRange, log10(lambdaRange), log10(Ampl(:,:,2)));
            title('absorber');
            xlabel('angular frequency');
            ylabel('log10(lambda)');
            zlabel('log10(amplitude');
            shading interp;

            figure();
            surf(omegaRange, log10(lambdaRange), log10(Ampl(:,:,1)));
            title('floor');
            xlabel('angular frequency');
            ylabel('log10(lambda)');
            zlabel('log10(amplitude');
            shading interp;

            figure();
            plot(log10(lambdaRange), log10(maxAmpls(:, 1)), 'DisplayName', 'Max Amplitude');
            title('Max amplitudes of floor');
            xlabel('log10(lambda)');
            ylabel('log10(amplitude)');

            figure();
            plot(log10(lambdaRange), (maxAmpls(:, 2)), 'DisplayName', 'Frequency');
            title('Frequencies at max amplitudes of floor');
            xlabel('log10(lambda)');
            ylabel('frequency');
        end
    end
end

figure();
surf(lambdaFloor, log10(lambdaRange), log10(maxAmplitudes));
title('Max amplitudes of floor');
xlabel('floor lambda');
ylabel('log10(absorber lambda)');
zlabel('log10(amplitude)');
shading interp;


optimalAbsorber = zeros(floorLambdaLength,1);
minAmplitude = zeros(floorLambdaLength,1);
maxAmplitude = zeros(floorLambdaLength,1);
ratio = zeros(floorLambdaLength,1);
for i = 1:floorLambdaLength
    minAmplitude(i) = min(maxAmplitudes(:,i));
    maxAmplitude(i) = max(maxAmplitudes(:,i));
    ratio(i) = minAmplitude(i)/maxAmplitude(i);
    optimalAbsorber(i) = lambdaRange(find(maxAmplitudes(:,i)==minAmplitude(i),1));
end

if (1)
    figure();
    plot(lambdaFloor, log10(minAmplitude));
    title('min floor amplitude for different floor lambdas');
    xlabel('floor lambda');
    ylabel('log10(floor amplitude)');
end

if (1)
    figure();
    plot(lambdaFloor, ratio);
    title('ratio of min and max amplitudes over floor lambda range');
    xlabel('floor lambda');
    ylabel('min amplitude/max amplitude');
end

if (1)
    figure();
    plot(lambdaFloor, optimalAbsorber);
    title('optimal absorber for different floor lambdas');
    xlabel('floor lambda');
    ylabel('optimal absorber damping');
end
