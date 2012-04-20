function [ IntervalFitnessPVal, IntervalGapPVal ] = arrayfun_BpmTest( k )

	global Beats;
	global HalfGapWindowSize;
	global GapWindow;
	global NumBeats;
	global BeatStrengths;

	global IntervalFrequency;
	global MinimumInterval;

	i = (k - 1) * IntervalFrequency + MinimumInterval;

	Gaps = mod( Beats, i );
	ExtraGaps = Gaps + i;

	FullGaps = [ Gaps ExtraGaps ]';
	FullGaps = FullGaps(:);
	[ SortedGaps SortedIndex ] = sort( FullGaps );

	% Here we take a hamming window over a small window of Gap positions
	% and record the amount of support we get from gap values within that
	% hamming window, based on the strength of the beat predicting each
	% gap and the distance of the gap from the centre of the hamming
	% window.
	GapsFiltered = zeros( NumBeats, 1 );
	for ct1 = 1 : NumBeats
		Area = 0;
		
		Centre = SortedGaps( ct1 );
		
		Pos = ct1;
		PosVal = SortedGaps( Pos );
		while ( PosVal > Centre - HalfGapWindowSize )

			if Pos <= 1 
				break;
			end
			xPos = SortedIndex( Pos );
			if ( xPos > size( Beats,1 ) ) 
				xPos = xPos - size( Beats,1 );
			end
			Area = Area + ( BeatStrengths( xPos ) * GapWindow( PosVal - (Centre - HalfGapWindowSize) ) );
			Pos = Pos - 1;
			PosVal = SortedGaps( Pos );
		end
		
		Pos = ct1;
		PosVal = SortedGaps( Pos );
		while ( PosVal <= Centre + HalfGapWindowSize )

			if Pos >= NumBeats
				break;
			end
			xPos = SortedIndex( Pos );
			if ( xPos > size( Beats,1 ) ) 
				xPos = xPos - size( Beats,1 );
			end
			Area = Area + ( BeatStrengths( xPos ) * GapWindow( PosVal - (Centre - HalfGapWindowSize) ) );
			Pos = Pos + 1;
			PosVal = SortedGaps( Pos );
		end
		
		GapsFiltered( ct1 ) = Area;
	end

	% Here we work out how much evidence there is to support each gap
	% by the GapFiltered value for each gap and a portion of the
	% GapFiltered value from offbeats.

	% Need to take care of end cases better
	GapsConfidence = zeros( NumBeats, 1 );
	for ct1 = 1 : NumBeats -1 
		
		OffbeatPos = SortedGaps( ct1 ) + round(i / 2);

		% We know the position of where an offbeat gap value would be but
		% we need to work out its index in the SortedGaps array
		Pos = ct1;
		PosVal = SortedGaps( Pos );
		while ( PosVal < OffbeatPos )
			if Pos >= NumBeats - 1
				break;
			end
			Pos = Pos + 1;
			PosVal = SortedGaps( Pos );
		end

		% Not sure why I have this taking the average of the two nearest
		% gaps. Might give some improvement to accuracy, but most probably
		% pointless. TODO?
		OffBeatValue = ( GapsFiltered( Pos ) + GapsFiltered( Pos + 1 ) ) / 2;

		GapsConfidence( ct1 ) = GapsFiltered( ct1 ) + ( OffBeatValue * 0.5 );        
	end

	GapPeaks = SortedGaps( find( GapsConfidence == max( GapsConfidence ) ) );

	IntervalFitnessPVal = max(GapsConfidence);
	IntervalGapPVal = GapPeaks(1);
end