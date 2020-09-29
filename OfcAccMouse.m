classdef OfcAccMouse < Mouse
    %ACCOFCMOUSE Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (Constant)
         GCAMP = 'Ofc'
         JRGECO = 'Acc'
     end
    
    methods
        function obj = OfcAccMouse(name, gcampJrGecoReversed, saveLocation)
            %MOUSE Construct an instance of this class
            obj@Mouse(name, gcampJrGecoReversed, saveLocation);
        end
    end
end