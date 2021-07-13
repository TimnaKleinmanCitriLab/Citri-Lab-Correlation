classdef OfcAccMouse < Mouse
    % A class for mice of type OfcAcc
    
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