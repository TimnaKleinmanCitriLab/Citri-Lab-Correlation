classdef OfcAccMouse < Mouse
    %ACCOFCMOUSE Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (Constant)
         GCAMP = 'Ofc'
         JRGECO = 'Acc'
     end
    
    methods
        function obj = OfcAccMouse(name, gcampJrGecoReversed)
            %MOUSE Construct an instance of this class
            obj@Mouse(name, gcampJrGecoReversed, "OfcAccMice");
        end
    end
end