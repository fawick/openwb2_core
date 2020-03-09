#!/bin/bash
sofortlademodus(){
if (( awattaraktiv == 1 )); then
	actualprice=$(<ramdisk/awattarprice)
	if (( $(echo "$actualprice < $awattarmaxprice" |bc -l) )); then
		#price lower than max price, enable charging
		if [[ $debug == "1" ]]; then
			echo "Aktiviere preisbasierte Ladung"
		fi
		if (( lp1enabled == 0 )); then
			mosquitto_pub -r -t openWB/set/lp1/ChargePointEnabled -m "1"	
		fi
		if (( lp2enabled == 0 )); then
			mosquitto_pub -r -t openWB/set/lp2/ChargePointEnabled -m "1"
		fi
		if (( lp3enabled == 0 )); then
			mosquitto_pub -r -t openWB/set/lp3/ChargePointEnabled -m "1"	
		fi
	else
		if [[ $debug == "1" ]]; then
			echo "Deaktiviere preisbasierte Ladung"
		fi
		#price higher than max price, disable charging
		if (( lp1enabled == 1 )); then
			mosquitto_pub -r -t openWB/set/lp1/ChargePointEnabled -m "0"	
		fi
		if (( lp2enabled == 1 )); then
			mosquitto_pub -r -t openWB/set/lp2/ChargePointEnabled -m "0"
		fi
		if (( lp3enabled == 1 )); then
			mosquitto_pub -r -t openWB/set/lp3/ChargePointEnabled -m "0"	
		fi

	fi
fi
if (( lastmmaxw < 10 ));then
	lastmmaxw=40000
fi
aktgeladen=$(<ramdisk/aktgeladen)
#mit einem Ladepunkt
if [[ $lastmanagement == "0" ]]; then
	if (( sofortsocstatlp1 == "1" )); then
		if (( soc >= sofortsoclp1 )); then
			if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatus"; then
				runs/set-current.sh 0 all
				echo "$date LP1, Lademodus Sofort. Ladung gestoppt, $soc % SoC erreicht" >> ramdisk/ladestatus.log
				if [[ $debug == "1" ]]; then
					echo "Beende Sofort Laden da $sofortsoclp1 % erreicht"
				fi
			fi
			exit 0
		fi	
	fi
	if grep -q 0 "/var/www/html/openWB/ramdisk/ladestatus"; then
		if (( lademstat == "1" )); then
			if (( $(echo "$aktgeladen > $lademkwh" |bc -l) )); then
				if [[ $debug == "1" ]]; then
       	             			echo "Sofort ladung beendet da $lademkwh kWh lademenge erreicht"
     				fi
			else
				runs/set-current.sh $minimalstromstaerke all
				echo "$date LP1, Lademodus Sofort. Ladung gestartet mit $minimalstromstaerke Ampere" >> ramdisk/ladestatus.log
				if [[ $debug == "1" ]]; then
	        		       	echo starte sofort Ladeleistung von $minimalstromstaerke aus
       				fi
				exit 0
			fi
		else
			runs/set-current.sh $minimalstromstaerke all
			if [[ $debug == "1" ]]; then
	        	       	echo starte sofort Ladeleistung von $minimalstromstaerke aus
       			fi
			exit 0
		fi
	fi
	if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatus"; then
		if (( lademstat == "1" )) && (( $(echo "$aktgeladen > $lademkwh" |bc -l) )); then
			runs/set-current.sh 0 m
			echo "$date LP1, Lademodus Sofort. Ladung gestoppt da $lademkwh kWh Limit erreicht" >> ramdisk/ladestatus.log

			if [[ $debug == "1" ]]; then
	        	       	echo "Beende Sofort Laden da  $lademkwh kWh erreicht"
       			fi
		else
			if (( evua1 < lastmaxap1 )) && (( evua2 < lastmaxap2 )) &&  (( evua3 < lastmaxap3 )); then
				if (( ladeleistunglp1 < 100 )); then
					if (( llalt > minimalstromstaerke )); then
        	                        	llneu=$((llalt - 1 ))
        	                        	runs/set-current.sh $llneu m
						echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
						if [[ $debug == "1" ]]; then
		       	             			echo "Sofort ladung reudziert auf $llneu bei minimal A $minimalstromstaerke Ladeleistung zu gering"
		     				fi
	       	                        	exit 0
					fi
					if (( llalt == minimalstromstaerke )); then
						if [[ $debug == "1" ]]; then
		       	             			echo "Sofort ladung bei minimal A $minimalstromstaerke Ladeleistung zu gering"
		     				fi
						exit 0
					fi
					if (( llalt < minimalstromstaerke )); then
						llneu=$minimalstromstaerke
						runs/set-current.sh $llneu m
						echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
						if [[ $debug == "1" ]]; then
      		             				echo "Sofort ladung erhöht auf $llneu bei minimal A $minimalstromstaerke Ladeleistung zu gering"
 						fi
						exit 0
					fi
				else
					if (( llalt < minimalstromstaerke )); then
						llneu=$minimalstromstaerke
						runs/set-current.sh $llneu m
						echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
						if [[ $debug == "1" ]]; then
      		             				echo "Sofort ladung erhöht auf $llneu bei minimal A $minimalstromstaerke"
 						fi
						exit 0
					fi
					if (( llalt > maximalstromstaerke )); then
						llneu=$((llalt - 1 ))
						runs/set-current.sh "$llneu" m
						echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung auf $llneu reduziert, über eingestellter max A $maximalstromstaerke"
						fi
						exit 0
					fi
					if (( llalt == sofortll )); then
						if [[ $debug == "1" ]]; then
       		        	     			echo "Sofort ladung erreicht bei $sofortll A"
     						fi
						exit 0
					fi
					if (( llalt < sofortll)); then
						evudiff1=$((lastmaxap1 - evua1 ))
						evudiff2=$((lastmaxap2 - evua2 ))
						evudiff3=$((lastmaxap3 - evua3 ))
						evudiffmax=($evudiff1 $evudiff2 $evudiff3)
						maxdiff=${evudiffmax[0]}
						for v in "${evudiffmax[@]}"; do
							if (( v < maxdiff )); then maxdiff=$v; fi;
						done
						llneu=$((llalt + maxdiff))
						if (( llneu > sofortll )); then
							llneu=$sofortll
						fi
						if (( llneu < sofortll )); then
							echo "Lastmanagement aktiv, Ladeleistung reduziert" > ramdisk/lastregelungaktiv
						fi 
						if (( llalt > maximalstromstaerke )); then
							llneu=$((llalt - 1 ))
							runs/set-current.sh "$llneu" m
							echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
							if [[ $debug == "1" ]]; then
								echo "Sofort ladung auf $llneu reduziert, über eingestellter max A $maximalstromstaerke"
							fi
							exit 0
						fi
						runs/set-current.sh "$llneu" m
						echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere, Lastmanagement aktiv" >> ramdisk/ladestatus.log
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung um $maxdiff A Differenz auf $llneu A erhoeht, kleiner als sofortll $sofortll"
						fi
						exit 0
					fi
					if (( llalt > sofortll)); then
						llneu=$sofortll
						if (( llalt > maximalstromstaerke )); then
							llneu=$((llalt - 1 ))
							runs/set-current.sh "$llneu" m
							echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
							if [[ $debug == "1" ]]; then
								echo "Sofort ladung auf $llneu reduziert, über eingestellter max A $maximalstromstaerke"
							fi
							exit 0
						fi
						runs/set-current.sh "$llneu" m
						echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung von $llalt A llalt auf $llneu A reduziert, größer als sofortll $sofortll"
						fi
						exit 0
					fi
				fi
			else
				evudiff1=$((evua1 - lastmaxap1 ))
				evudiff2=$((evua2 - lastmaxap2 ))
				evudiff3=$((evua3 - lastmaxap3 ))
				evudiffmax=($evudiff1 $evudiff2 $evudiff3)
				maxdiff=${evudiffmax[0]}
				for v in "${evudiffmax[@]}"; do
					if (( v > maxdiff )); then maxdiff=$v; fi;
				done
				maxdiff=$((maxdiff + 1 ))
				llneu=$((llalt - maxdiff))
				echo "Lastmanagement aktiv, Ladeleistung reduziert" > ramdisk/lastregelungaktiv
				if (( llneu < minimalstromstaerke )); then
					llneu=$minimalstromstaerke
					if [[ $debug == "1" ]]; then
						echo Differenz groesser als minimalstromstaerke, setze auf minimal A $minimalstromstaerke
					fi
				fi
				runs/set-current.sh "$llneu" m
				echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere, Lastmanagement aktiv" >> ramdisk/ladestatus.log
				if [[ $debug == "1" ]]; then
					echo "Sofort ladung um $maxdiff auf $llneu reduziert"
				fi
				exit 0
			fi
		fi
	fi
else
	activechargepoints=0
	if (( ladeleistunglp1 > 100)); then activechargepoints=$((activechargepoints + 1)); fi
	if (( ladeleistunglp2 > 100)); then activechargepoints=$((activechargepoints + 1)); fi
	if (( ladeleistunglp3 > 100)); then activechargepoints=$((activechargepoints + 1)); fi
	if (( ladeleistunglp4 > 100)); then activechargepoints=$((activechargepoints + 1)); fi
	if (( ladeleistunglp5 > 100)); then activechargepoints=$((activechargepoints + 1)); fi
	if (( ladeleistunglp6 > 100)); then activechargepoints=$((activechargepoints + 1)); fi
	if (( ladeleistunglp7 > 100)); then activechargepoints=$((activechargepoints + 1)); fi
	if (( ladeleistunglp8 > 100)); then activechargepoints=$((activechargepoints + 1)); fi
	#mit mehr als einem ladepunkt
	aktgeladens1=$(<ramdisk/aktgeladens1)
	if (( evua1 < lastmaxap1 )) && (( evua2 < lastmaxap2 )) &&  (( evua3 < lastmaxap3 )) && (( wattbezug < lastmmaxw )); then
		evudiff1=$((lastmaxap1 - evua1 ))
		evudiff2=$((lastmaxap2 - evua2 ))
		evudiff3=$((lastmaxap3 - evua3 ))
		evudiffmax=($evudiff1 $evudiff2 $evudiff3)
		maxdiff=${evudiffmax[0]}
		for v in "${evudiffmax[@]}"; do
			if (( v < maxdiff )); then maxdiff=$v; fi;
		done
		maxdiff=$((maxdiff - 1 ))
		maxdiffw=$(( lastmmaxw - wattbezug ))
		maxdiffwa=$(( maxdiffw / 230 ))
		maxdiffwa=$(( maxdiffwa - 2 ))

		if (( maxdiffwa > maxdiff )); then
			maxdiff=$maxdiff
			echo "Ampere beschränkt"
		else
			maxdiff=$maxdiffwa
			echo "Leistung beschränkt"
		fi
		if (( maxdiff < 0 )); then
			maxdiff=0
		fi

		if (( activechargepoints > 1 )); then
			maxdiff=$(echo "($maxdiff / $activechargepoints) / 1" |bc)
		fi

		#Ladepunkt 1
		if (( sofortsocstatlp1 == "1" )); then
			if (( soc > sofortsoclp1 )); then
				if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatus"; then
					runs/set-current.sh 0 m
					echo "$date LP1, Lademodus Sofort. Ladung gestoppt, $sofortsoclp1 % SoC erreicht" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Beende Sofort Laden da $sofortsoclp1 % erreicht"
					fi
				fi
			else
				if (( ladeleistunglp1 < 100 )); then
					if (( llalt > minimalstromstaerke )); then
						llneu=$((llalt - 1 ))
						runs/set-current.sh "$llneu" m
						echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 1 reudziert auf $llneu bei minimal A $minimalstromstaerke Ladeleistung zu gering"
						fi
					fi
					if (( llalt == minimalstromstaerke )); then
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 1 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
						fi
					fi
					if (( llalt < minimalstromstaerke )); then
						llneu=$minimalstromstaerke
						runs/set-current.sh "$llneu" m
						echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 1 erhöht auf $llneu bei minimal A $minimalstromstaerke Ladeleistung zu gering"
						fi
					fi
				else
					if (( llalt == sofortll )); then
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 1 erreicht bei $sofortll A"
						fi
					fi
					if (( llalt > maximalstromstaerke )); then
						llneu=$((llalt - 1 ))
						runs/set-current.sh "$llneu" m
						echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 1 auf $llneu reduziert, über eingestellter max A $maximalstromstaerke"
						fi
					else
						if (( llalt < sofortll)); then

							llneu=$((llalt + maxdiff))
							if (( llneu > sofortll )); then
								llneu=$sofortll
							fi
							if (( llneu < sofortll )); then
								echo "Lastmanagement aktiv, Ladeleistung reduziert" > ramdisk/lastregelungaktiv
							fi
							runs/set-current.sh "$llneu" m
							if [[ $debug == "1" ]]; then
								echo "Sofort ladung Ladepunkt 1 um $maxdiff A Differenz auf $llneu A erhoeht, war kleiner als sofortll $sofortll"
							fi
						fi
						if (( llalt > sofortll)); then
							llneu=$sofortll
							runs/set-current.sh "$llneu" m
							echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
							if [[ $debug == "1" ]]; then
								echo "Sofort ladung Ladepunkt 1 von $llalt A llalt auf $llneu A reduziert, war größer als sofortll $sofortll"
							fi
						fi
					fi
					if (( llalt < minimalstromstaerke )); then
						llneu=$minimalstromstaerke
						runs/set-current.sh "$llneu" m
						echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 1 erhöht auf $llneu bei minimal A $minimalstromstaerke Ladeleistung zu gering"
						fi
					fi

				fi
			fi

		else	
		if (( lademstat == "1" )) && (( $(echo "$aktgeladen > $lademkwh" |bc -l) )); then
			if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatus"; then
				runs/set-current.sh 0 m
				echo "$date LP1, Lademodus Sofort. Ladung gestoppt da $lademkwh kWh Limit erreicht" >> ramdisk/ladestatus.log
				if [[ $debug == "1" ]]; then
					echo "Beende Sofort Laden an Ladepunkt 1 da  $lademkwh kWh erreicht"
				fi
			fi
		else
			if (( ladeleistunglp1 < 100 )); then
				if (( llalt > minimalstromstaerke )); then
					llneu=$((llalt - 1 ))
					runs/set-current.sh "$llneu" m
					echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 1 reudziert auf $llneu bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
				if (( llalt == minimalstromstaerke )); then
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 1 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
				if (( llalt < minimalstromstaerke )); then
					llneu=$minimalstromstaerke
					runs/set-current.sh "$llneu" m
					echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 1 erhöht auf $llneu bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
			else
				if (( llalt == sofortll )); then
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 1 erreicht bei $sofortll A"
					fi
				fi
				if (( llalt > maximalstromstaerke )); then
					llneu=$((llalt - 1 ))
					runs/set-current.sh "$llneu" m
					echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 1 auf $llneu reduziert, über eingestellter max A $maximalstromstaerke"
					fi
				else
					if (( llalt < sofortll)); then
						llneu=$((llalt + maxdiff))
						if (( llneu > sofortll )); then
							llneu=$sofortll
						fi
						if (( llneu < sofortll )); then
							echo "Lastmanagement aktiv, Ladeleistung reduziert" > ramdisk/lastregelungaktiv
						fi
						runs/set-current.sh "$llneu" m
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 1 um $maxdiff A Differenz auf $llneu A erhoeht, war kleiner als sofortll $sofortll"
						fi
					fi
					if (( llalt > sofortll)); then
						llneu=$sofortll
						runs/set-current.sh "$llneu" m
						echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 1 von $llalt A llalt auf $llneu A reduziert, war größer als sofortll $sofortll"
						fi
					fi
				fi
				if (( llalt < minimalstromstaerke )); then
					llneu=$minimalstromstaerke
					runs/set-current.sh "$llneu" m
					echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 1 erhöht auf $llneu bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
			fi
			
		fi
	fi
	#Ladepunkt 2
	if (( sofortsocstatlp2 == 1 )); then
		if (( soc1 > sofortsoclp2 )); then
			if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatuss1"; then
				runs/set-current.sh 0 s1
				echo "$date LP2, Lademodus Sofort. Ladung gestoppt da $sofortsoclp2 % SoC erreicht" >> ramdisk/ladestatus.log
				if [[ $debug == "1" ]]; then
					echo "Beende Sofort Laden an Ladepunkt 2 da  $sofortsoclp2 % erreicht"
				fi
			fi
		else
			if (( ladeleistungs1 < 100 )); then
				if (( llalts1 > minimalstromstaerke )); then
					llneus1=$((llalts1 - 1 ))
					runs/set-current.sh "$llneus1" s1
					echo "$date LP2, Lademodus Sofort. Ladung geändert auf $llneus1 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 2 reudziert auf $llneus1 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
				if (( llalts1 == minimalstromstaerke )); then
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 2 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
				if (( llalts1 < minimalstromstaerke )); then
					llneus1=$minimalstromstaerke
					runs/set-current.sh "$llneus1" s1
					echo "$date LP2, Lademodus Sofort. Ladung geändert auf $llneus1 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 2 erhöht auf $llneus1 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
			else
				if (( llalts1 == sofortlls1 )); then
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 2 erreicht bei $sofortlls1 A"
					fi
				fi
				if (( llalts1 > maximalstromstaerke )); then
					llneus1=$((llalts1 - 1 ))
					runs/set-current.sh "$llneus1" s1
					echo "$date LP2, Lademodus Sofort. Ladung geändert auf $llneus1 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 2 auf $llneus1 reduziert, über eingestellter max A $maximalstromstaerke"
					fi
				else
					if (( llalts1 < sofortlls1)); then
						llneus1=$((llalts1 + maxdiff))
						if (( llneus1 > sofortlls1 )); then
							llneus1=$sofortlls1
						fi
						if (( llneus1 < sofortlls1 )); then
							echo "Lastmanagement aktiv, Ladeleistung reduziert" > ramdisk/lastregelungaktiv
						fi 
						runs/set-current.sh "$llneus1" s1
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 2 um $maxdiff A Differenz auf $llneus1 A erhoeht, war kleiner als sofortll $sofortlls1"
						fi
					fi
					if (( llalts1 > sofortlls1)); then
						llneus1=$sofortlls1
						runs/set-current.sh "$llneus1" s1
						echo "$date LP2, Lademodus Sofort. Ladung geändert auf $llneus1 Ampere" >> ramdisk/ladestatus.log
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 2 von $llalts1 A llalt auf $llneus1 A reduziert, war größer als sofortll $sofortlls1"
						fi
					fi
				fi
				if (( llalts1 < minimalstromstaerke )); then
					llneus1=$minimalstromstaerke
					runs/set-current.sh "$llneus1" s1
					echo "$date LP2, Lademodus Sofort. Ladung geändert auf $llneus1 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 2 erhöht auf $llneus1 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
			fi
		fi
	else	
		if (( lademstats1 == "1" )) && (( $(echo "$aktgeladens1 > $lademkwhs1" |bc -l) )); then
			if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatuss1"; then
				runs/set-current.sh 0 s1
				echo "$date LP2, Lademodus Sofort. Ladung gestoppt da $lademkwhs1 kWh erreicht" >> ramdisk/ladestatus.log
				if [[ $debug == "1" ]]; then
					echo "Beende Sofort Laden an Ladepunkt 2 da  $lademkwhs1 kWh erreicht"
				fi
			fi
		else
			if (( ladeleistungs1 < 100 )); then
				if (( llalts1 > minimalstromstaerke )); then
					llneus1=$((llalts1 - 1 ))
					runs/set-current.sh "$llneus1" s1
					echo "$date LP2, Lademodus Sofort. Ladung geändert auf $llneus1 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 2 reudziert auf $llneus1 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
				if (( llalts1 == minimalstromstaerke )); then
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 2 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
				if (( llalts1 < minimalstromstaerke )); then
					llneus1=$minimalstromstaerke
					runs/set-current.sh "$llneus1" s1
					echo "$date LP2, Lademodus Sofort. Ladung geändert auf $llneus1 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 2 erhöht auf $llneus1 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
			else
				if (( llalts1 == sofortlls1 )); then
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 2 erreicht bei $sofortlls1 A"
					fi
				fi
				if (( llalts1 > maximalstromstaerke )); then
					llneus1=$((llalts1 - 1 ))
					runs/set-current.sh "$llneus1" s1
					echo "$date LP2, Lademodus Sofort. Ladung geändert auf $llneus1 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 2 auf $llneus1 reduziert, über eingestellter max A $maximalstromstaerke"
					fi
				else
					if (( llalts1 < sofortlls1)); then
						llneus1=$((llalts1 + maxdiff))
						if (( llneus1 > sofortlls1 )); then
							llneus1=$sofortlls1
						fi
						if (( llneus1 < sofortlls1 )); then
							echo "Lastmanagement aktiv, Ladeleistung reduziert" > ramdisk/lastregelungaktiv
						fi 
						runs/set-current.sh "$llneus1" s1
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 2 um $maxdiff A Differenz auf $llneus1 A erhoeht, war kleiner als sofortll $sofortlls1"
						fi
					fi
					if (( llalts1 > sofortlls1)); then
						llneus1=$sofortlls1
						runs/set-current.sh "$llneus1" s1
						echo "$date LP2, Lademodus Sofort. Ladung geändert auf $llneus1 Ampere" >> ramdisk/ladestatus.log
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 2 von $llalts1 A llalt auf $llneus1 A reduziert, war größer als sofortll $sofortlls1"
						fi
					fi
				fi
				if (( llalts1 < minimalstromstaerke )); then
					llneus1=$minimalstromstaerke
					runs/set-current.sh "$llneus1" s1
					echo "$date LP2, Lademodus Sofort. Ladung geändert auf $llneus1 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 2 erhöht auf $llneus1 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
			fi
		fi
	fi

	#Ladepunkt 3
	if [[ $lastmanagements2 == "1" ]]; then
		aktgeladens2=$(<ramdisk/aktgeladens2)
		if (( lademstats2 == "1" )) && (( $(echo "$aktgeladens2 > $lademkwhs2" |bc -l) )); then
			if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatuss2"; then
				runs/set-current.sh 0 s2
			echo "$date LP3, Lademodus Sofort. Ladung gestoppt da $lademkwhs2 kWh Limit erreicht" >> ramdisk/ladestatus.log
				if [[ $debug == "1" ]]; then
					echo "Beende Sofort Laden an Ladepunkt 3 da  $lademkwhs2 kWh erreicht"
				fi
			fi
		else
			if (( ladeleistungs2 < 100 )); then
				if (( llalts2 > minimalstromstaerke )); then
					llneus2=$((llalts2 - 1 ))
					runs/set-current.sh "$llneus2" s2
					echo "$date LP3, Lademodus Sofort. Ladung geändert auf $llneus2 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 3 reudziert auf $llneus2 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
				if (( llalts2 == minimalstromstaerke )); then
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 3 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
				if (( llalts2 < minimalstromstaerke )); then
					llneus2=$minimalstromstaerke
					runs/set-current.sh "$llneus2" s2
					echo "$date LP3, Lademodus Sofort. Ladung geändert auf $llneus2 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 3 erhöht auf $llneus2 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
			else
				if (( llalts2 == sofortlls2 )); then
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 3 erreicht bei $sofortlls2 A"
					fi
				fi
				if (( llalts2 > maximalstromstaerke )); then
					llneus2=$((llalts2 - 1 ))
					runs/set-current.sh "$llneus2" s2
					echo "$date LP3, Lademodus Sofort. Ladung geändert auf $llneus2 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 3 auf $llneus2 reduziert, über eingestellter max A $maximalstromstaerke"
					fi
				else
					if (( llalts2 < sofortlls2)); then
						llneus2=$((llalts2 + maxdiff))
						if (( llneus2 > sofortlls2 )); then
							llneus2=$sofortlls2
						fi
						if (( llneus2 < sofortlls2 )); then
							echo "Lastmanagement aktiv, Ladeleistung reduziert" > ramdisk/lastregelungaktiv
						fi 
						runs/set-current.sh "$llneus2" s2
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 3 um $maxdiff A Differenz auf $llneus2 A erhoeht, war kleiner als sofortll $sofortlls2"
						fi
					fi
					if (( llalts2 > sofortlls2)); then
						llneus2=$sofortlls2
						runs/set-current.sh "$llneus2" s2
						echo "$date LP3, Lademodus Sofort. Ladung geändert auf $llneus2 Ampere, Lastmanagement aktiv" >> ramdisk/ladestatus.log
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 3 von $llalts2 A llalt auf $llneus2 A reduziert, war größer als sofortll $sofortlls2"
						fi
					fi
				fi
			fi
		fi
	fi
	#Ladepunkt 4
	if [[ $lastmanagementlp4 == "1" ]]; then
		aktgeladenlp4=$(<ramdisk/aktgeladenlp4)
		if (( lademstatlp4 == "1" )) && (( $(echo "$aktgeladenlp4 > $lademkwhlp4" |bc -l) )); then
			if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatuslp4"; then
				runs/set-current.sh 0 lp4
			echo "$date LP4, Lademodus Sofort. Ladung gestoppt da $lademkwhlp4 kWh Limit erreicht" >> ramdisk/ladestatus.log
				if [[ $debug == "1" ]]; then
					echo "Beende Sofort Laden an Ladepunkt 4 da  $lademkwhlp4 kWh erreicht"
				fi
			fi
		else
			if (( ladeleistunglp4 < 100 )); then
				if (( llaltlp4 > minimalstromstaerke )); then
					llneulp4=$((llaltlp4 - 1 ))
					runs/set-current.sh "$llneulp4" lp4
					echo "$date LP4, Lademodus Sofort. Ladung geändert auf $llneulp4 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 4 reudziert auf $llneulp4 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
				if (( llaltlp4 == minimalstromstaerke )); then
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 4 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
				if (( llaltlp4 < minimalstromstaerke )); then
					llneulp4=$minimalstromstaerke
					runs/set-current.sh "$llneulp4" lp4
					echo "$date LP4, Lademodus Sofort. Ladung geändert auf $llneulp4 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 4 erhöht auf $llneulp4 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
			else
				if (( llaltlp4 == sofortlllp4 )); then
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 4 erreicht bei $sofortlllp4 A"
					fi
				fi
				if (( llaltlp4 > maximalstromstaerke )); then
					llneulp4=$((llaltlp4 - 1 ))
					runs/set-current.sh "$llneulp4" lp4
					echo "$date LP4, Lademodus Sofort. Ladung geändert auf $llneulp4 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 4 auf $llneulp4 reduziert, über eingestellter max A $maximalstromstaerke"
					fi
				else
					if (( llaltlp4 < sofortlllp4)); then
						llneulp4=$((llaltlp4 + maxdiff))
						if (( llneulp4 > sofortlllp4 )); then
							llneulp4=$sofortlllp4
						fi
						if (( llneulp4 < sofortlllp4 )); then
							echo "Lastmanagement aktiv, Ladeleistung reduziert" > ramdisk/lastregelungaktiv
						fi 
						runs/set-current.sh "$llneulp4" lp4
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 4 um $maxdiff A Differenz auf $llneulp4 A erhoeht, war kleiner als sofortll $sofortlllp4"
						fi
					fi
					if (( llaltlp4 > sofortlllp4)); then
						llneulp4=$sofortlllp4
						runs/set-current.sh "$llneulp4" lp4
						echo "$date LP4, Lademodus Sofort. Ladung geändert auf $llneulp4 Ampere, Lastmanagement aktiv" >> ramdisk/ladestatus.log
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 4 von $llaltlp4 A llalt auf $llneulp4 A reduziert, war größer als sofortll $sofortlllp4"
						fi
					fi
				fi
			fi
		fi
	fi
	#Ladepunkt 5
	if [[ $lastmanagementlp5 == "1" ]]; then
		aktgeladenlp5=$(<ramdisk/aktgeladenlp5)
		if (( lademstatlp5 == "1" )) && (( $(echo "$aktgeladenlp5 > $lademkwhlp5" |bc -l) )); then
			if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatuslp5"; then
				runs/set-current.sh 0 lp5
			echo "$date LP5, Lademodus Sofort. Ladung gestoppt da $lademkwhlp5 kWh Limit erreicht" >> ramdisk/ladestatus.log
				if [[ $debug == "1" ]]; then
					echo "Beende Sofort Laden an Ladepunkt 5 da  $lademkwhlp5 kWh erreicht"
				fi
			fi
		else
			if (( ladeleistunglp5 < 100 )); then
				if (( llaltlp5 > minimalstromstaerke )); then
					llneulp5=$((llaltlp5 - 1 ))
					runs/set-current.sh "$llneulp5" lp5
					echo "$date LP5, Lademodus Sofort. Ladung geändert auf $llneulp5 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 5 reudziert auf $llneulp5 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
				if (( llaltlp5 == minimalstromstaerke )); then
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 5 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
				if (( llaltlp5 < minimalstromstaerke )); then
					llneulp5=$minimalstromstaerke
					runs/set-current.sh "$llneulp5" lp5
					echo "$date LP5, Lademodus Sofort. Ladung geändert auf $llneulp5 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 5 erhöht auf $llneulp5 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
			else
				if (( llaltlp5 == sofortlllp5 )); then
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 5 erreicht bei $sofortlllp5 A"
					fi
				fi
				if (( llaltlp5 > maximalstromstaerke )); then
					llneulp5=$((llaltlp5 - 1 ))
					runs/set-current.sh "$llneulp5" lp5
					echo "$date LP5, Lademodus Sofort. Ladung geändert auf $llneulp5 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 5 auf $llneulp5 reduziert, über eingestellter max A $maximalstromstaerke"
					fi
				else
					if (( llaltlp5 < sofortlllp5)); then
						llneulp5=$((llaltlp5 + maxdiff))
						if (( llneulp5 > sofortlllp5 )); then
							llneulp5=$sofortlllp5
						fi
						if (( llneulp5 < sofortlllp5 )); then
							echo "Lastmanagement aktiv, Ladeleistung reduziert" > ramdisk/lastregelungaktiv
						fi 
						runs/set-current.sh "$llneulp5" lp5
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 5 um $maxdiff A Differenz auf $llneulp5 A erhoeht, war kleiner als sofortll $sofortlllp5"
						fi
					fi
					if (( llaltlp5 > sofortlllp5)); then
						llneulp5=$sofortlllp5
						runs/set-current.sh "$llneulp5" lp5
						echo "$date LP5, Lademodus Sofort. Ladung geändert auf $llneulp5 Ampere, Lastmanagement aktiv" >> ramdisk/ladestatus.log
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 5 von $llaltlp5 A llalt auf $llneulp5 A reduziert, war größer als sofortll $sofortlllp5"
						fi
					fi
				fi
			fi
		fi
	fi
	#Ladepunkt 6
	if [[ $lastmanagementlp6 == "1" ]]; then
		aktgeladenlp6=$(<ramdisk/aktgeladenlp6)
		if (( lademstatlp6 == "1" )) && (( $(echo "$aktgeladenlp6 > $lademkwhlp6" |bc -l) )); then
			if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatuslp6"; then
				runs/set-current.sh 0 lp6
			echo "$date LP6, Lademodus Sofort. Ladung gestoppt da $lademkwhlp6 kWh Limit erreicht" >> ramdisk/ladestatus.log
				if [[ $debug == "1" ]]; then
					echo "Beende Sofort Laden an Ladepunkt 6 da  $lademkwhlp6 kWh erreicht"
				fi
			fi
		else
			if (( ladeleistunglp6 < 600 )); then
				if (( llaltlp6 > minimalstromstaerke )); then
					llneulp6=$((llaltlp6 - 1 ))
					runs/set-current.sh "$llneulp6" lp6
					echo "$date LP6, Lademodus Sofort. Ladung geändert auf $llneulp6 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 6 reudziert auf $llneulp6 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
				if (( llaltlp6 == minimalstromstaerke )); then
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 6 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
				if (( llaltlp6 < minimalstromstaerke )); then
					llneulp6=$minimalstromstaerke
					runs/set-current.sh "$llneulp6" lp6
					echo "$date LP6, Lademodus Sofort. Ladung geändert auf $llneulp6 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 6 erhöht auf $llneulp6 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
			else
				if (( llaltlp6 == sofortlllp6 )); then
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 6 erreicht bei $sofortlllp6 A"
					fi
				fi
				if (( llaltlp6 > maximalstromstaerke )); then
					llneulp6=$((llaltlp6 - 1 ))
					runs/set-current.sh "$llneulp6" lp6
					echo "$date LP6, Lademodus Sofort. Ladung geändert auf $llneulp6 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 6 auf $llneulp6 reduziert, über eingestellter max A $maximalstromstaerke"
					fi
				else
					if (( llaltlp6 < sofortlllp6)); then
						llneulp6=$((llaltlp6 + maxdiff))
						if (( llneulp6 > sofortlllp6 )); then
							llneulp6=$sofortlllp6
						fi
						if (( llneulp6 < sofortlllp6 )); then
							echo "Lastmanagement aktiv, Ladeleistung reduziert" > ramdisk/lastregelungaktiv
						fi 
						runs/set-current.sh "$llneulp6" lp6
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 6 um $maxdiff A Differenz auf $llneulp6 A erhoeht, war kleiner als sofortll $sofortlllp6"
						fi
					fi
					if (( llaltlp6 > sofortlllp6)); then
						llneulp6=$sofortlllp6
						runs/set-current.sh "$llneulp6" lp6
						echo "$date LP6, Lademodus Sofort. Ladung geändert auf $llneulp6 Ampere, Lastmanagement aktiv" >> ramdisk/ladestatus.log
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 6 von $llaltlp6 A llalt auf $llneulp6 A reduziert, war größer als sofortll $sofortlllp6"
						fi
					fi
				fi
			fi
		fi
	fi
	#Ladepunkt 7
	if [[ $lastmanagementlp7 == "1" ]]; then
		aktgeladenlp7=$(<ramdisk/aktgeladenlp7)
		if (( lademstatlp7 == "1" )) && (( $(echo "$aktgeladenlp7 > $lademkwhlp7" |bc -l) )); then
			if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatuslp7"; then
				runs/set-current.sh 0 lp7
			echo "$date LP7, Lademodus Sofort. Ladung gestoppt da $lademkwhlp7 kWh Limit erreicht" >> ramdisk/ladestatus.log
				if [[ $debug == "1" ]]; then
					echo "Beende Sofort Laden an Ladepunkt 7 da  $lademkwhlp7 kWh erreicht"
				fi
			fi
		else
			if (( ladeleistunglp7 < 700 )); then
				if (( llaltlp7 > minimalstromstaerke )); then
					llneulp7=$((llaltlp7 - 1 ))
					runs/set-current.sh "$llneulp7" lp7
					echo "$date LP7, Lademodus Sofort. Ladung geändert auf $llneulp7 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 7 reudziert auf $llneulp7 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
				if (( llaltlp7 == minimalstromstaerke )); then
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 7 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
				if (( llaltlp7 < minimalstromstaerke )); then
					llneulp7=$minimalstromstaerke
					runs/set-current.sh "$llneulp7" lp7
					echo "$date LP7, Lademodus Sofort. Ladung geändert auf $llneulp7 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 7 erhöht auf $llneulp7 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
			else
				if (( llaltlp7 == sofortlllp7 )); then
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 7 erreicht bei $sofortlllp7 A"
					fi
				fi
				if (( llaltlp7 > maximalstromstaerke )); then
					llneulp7=$((llaltlp7 - 1 ))
					runs/set-current.sh "$llneulp7" lp7
					echo "$date LP7, Lademodus Sofort. Ladung geändert auf $llneulp7 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 7 auf $llneulp7 reduziert, über eingestellter max A $maximalstromstaerke"
					fi
				else
					if (( llaltlp7 < sofortlllp7)); then
						llneulp7=$((llaltlp7 + maxdiff))
						if (( llneulp7 > sofortlllp7 )); then
							llneulp7=$sofortlllp7
						fi
						if (( llneulp7 < sofortlllp7 )); then
							echo "Lastmanagement aktiv, Ladeleistung reduziert" > ramdisk/lastregelungaktiv
						fi 
						runs/set-current.sh "$llneulp7" lp7
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 7 um $maxdiff A Differenz auf $llneulp7 A erhoeht, war kleiner als sofortll $sofortlllp7"
						fi
					fi
					if (( llaltlp7 > sofortlllp7)); then
						llneulp7=$sofortlllp7
						runs/set-current.sh "$llneulp7" lp7
						echo "$date LP7, Lademodus Sofort. Ladung geändert auf $llneulp7 Ampere, Lastmanagement aktiv" >> ramdisk/ladestatus.log
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 7 von $llaltlp7 A llalt auf $llneulp7 A reduziert, war größer als sofortll $sofortlllp7"
						fi
					fi
				fi
			fi
		fi
	fi
	#Ladepunkt 8
	if [[ $lastmanagementlp8 == "1" ]]; then
		aktgeladenlp8=$(<ramdisk/aktgeladenlp8)
		if (( lademstatlp8 == "1" )) && (( $(echo "$aktgeladenlp8 > $lademkwhlp8" |bc -l) )); then
			if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatuslp8"; then
				runs/set-current.sh 0 lp8
			echo "$date LP8, Lademodus Sofort. Ladung gestoppt da $lademkwhlp8 kWh Limit erreicht" >> ramdisk/ladestatus.log
				if [[ $debug == "1" ]]; then
					echo "Beende Sofort Laden an Ladepunkt 8 da  $lademkwhlp8 kWh erreicht"
				fi
			fi
		else
			if (( ladeleistunglp8 < 800 )); then
				if (( llaltlp8 > minimalstromstaerke )); then
					llneulp8=$((llaltlp8 - 1 ))
					runs/set-current.sh "$llneulp8" lp8
					echo "$date LP8, Lademodus Sofort. Ladung geändert auf $llneulp8 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 8 reudziert auf $llneulp8 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
				if (( llaltlp8 == minimalstromstaerke )); then
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 8 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
				if (( llaltlp8 < minimalstromstaerke )); then
					llneulp8=$minimalstromstaerke
					runs/set-current.sh "$llneulp8" lp8
					echo "$date LP8, Lademodus Sofort. Ladung geändert auf $llneulp8 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 8 erhöht auf $llneulp8 bei minimal A $minimalstromstaerke Ladeleistung zu gering"
					fi
				fi
			else
				if (( llaltlp8 == sofortlllp8 )); then
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 8 erreicht bei $sofortlllp8 A"
					fi
				fi
				if (( llaltlp8 > maximalstromstaerke )); then
					llneulp8=$((llaltlp8 - 1 ))
					runs/set-current.sh "$llneulp8" lp8
					echo "$date LP8, Lademodus Sofort. Ladung geändert auf $llneulp8 Ampere" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Sofort ladung Ladepunkt 8 auf $llneulp8 reduziert, über eingestellter max A $maximalstromstaerke"
					fi
				else
					if (( llaltlp8 < sofortlllp8)); then
						llneulp8=$((llaltlp8 + maxdiff))
						if (( llneulp8 > sofortlllp8 )); then
							llneulp8=$sofortlllp8
						fi
						if (( llneulp8 < sofortlllp8 )); then
							echo "Lastmanagement aktiv, Ladeleistung reduziert" > ramdisk/lastregelungaktiv
						fi 
						runs/set-current.sh "$llneulp8" lp8
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 8 um $maxdiff A Differenz auf $llneulp8 A erhoeht, war kleiner als sofortll $sofortlllp8"
						fi
					fi
					if (( llaltlp8 > sofortlllp8)); then
						llneulp8=$sofortlllp8
						runs/set-current.sh "$llneulp8" lp8
						echo "$date LP8, Lademodus Sofort. Ladung geändert auf $llneulp8 Ampere, Lastmanagement aktiv" >> ramdisk/ladestatus.log
						if [[ $debug == "1" ]]; then
							echo "Sofort ladung Ladepunkt 8 von $llaltlp8 A llalt auf $llneulp8 A reduziert, war größer als sofortll $sofortlllp8"
						fi
					fi
				fi
			fi
		fi
	fi

	exit 0
	else
		if (( wattbezug < lastmmaxw )); then
			evudiff1=$((evua1 - lastmaxap1 ))
			evudiff2=$((evua2 - lastmaxap2 ))
			evudiff3=$((evua3 - lastmaxap3 ))
			evudiffmax=($evudiff1 $evudiff2 $evudiff3)
			maxdiff=0
			for v in "${evudiffmax[@]}"; do
				if (( v > maxdiff )); then maxdiff=$v; fi;
			done
			maxdiff=$((maxdiff + 1 ))
			if (( activechargepoints > 1 )); then
				maxdiff=$(echo "($maxdiff / $activechargepoints) / 1" |bc)
			fi
			echo "Lastmanagement aktiv (Ampere), Ladeleistung reduziert" > ramdisk/lastregelungaktiv
		else
			wattzuviel=$((wattbezug - lastmmaxw))
			amperezuviel=$(( wattzuviel / 230 ))
			maxdiff=$((amperezuviel + 2 ))
			if (( activechargepoints > 1 )); then
				maxdiff=$(echo "($maxdiff / $activechargepoints) / 1" |bc)
			fi
			echo "Lastmanagement aktiv (Leistung), Ladeleistung reduziert" > ramdisk/lastregelungaktiv

		fi
		llneu=$((llalt - maxdiff))
		llneus1=$((llalts1 - maxdiff))
		if [[ $lastmanagements2 == "1" ]]; then
			llneus2=$((llalts2 - maxdiff))
		fi
		if (( llneu < minimalstromstaerke )); then
			llneu=$minimalstromstaerke
			if [[ $debug == "1" ]]; then
				echo Ladepunkt 1 Differenz groesser als minimalstromstaerke, setze auf minimal A $minimalstromstaerke
			fi
		fi
		if (( llneus1 < minimalstromstaerke )); then
			llneus1=$minimalstromstaerke
			if [[ $debug == "1" ]]; then
				echo Ladepunkt 2 Differenz groesser als minimalstromstaerke, setze auf minimal A $minimalstromstaerke
			fi
		fi
		if [[ $lastmanagements2 == "1" ]]; then
			if (( llneus2 < minimalstromstaerke )); then
				llneus2=$minimalstromstaerke
				if [[ $debug == "1" ]]; then
				echo Ladepunkt 3 Differenz groesser als minimalstromstaerke, setze auf minimal A $minimalstromstaerke
				fi
			fi
		fi

		if (( sofortsocstatlp1 == 1 )); then
			if (( soc >= sofortsoclp1)); then
				if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatus"; then
					runs/set-current.sh 0 m
					echo "$date LP1, Lademodus Sofort. Ladung gstoppt da $socortsoclp1 % SoC erreicht" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Beende Sofort Laden da $sofortsoclp1 % erreicht"
					fi
				fi
			else
				runs/set-current.sh "$llneu" m
				echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
			fi
		fi
		if (( lademstat == 1 )); then
			if (( $(echo "$aktgeladen > $lademkwh" |bc -l) )); then
				if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatus"; then
					runs/set-current.sh 0 m
					echo "$date LP1, Lademodus Sofort. Ladung gstoppt da $lademkwh kWh erreicht" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Beende Sofort Laden an Ladepunkt 1 da  $lademkwh kWh erreicht"
					fi
				fi
			else
				runs/set-current.sh "$llneu" m
				echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
			fi
		fi
		if (( sofortsoctatlp1 == 0)) && (( lademstat == 0));then
			runs/set-current.sh "$llneu" m
			echo "$date LP1, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
		fi
		if (( sofortsocstatlp2 == 1 )); then
			if (( soc1 >= sofortsoclp2 )); then
				if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatuss1"; then
					runs/set-current.sh 0 s1
					echo "$date LP2, Lademodus Sofort. Ladung gstoppt da $sofortsoclp2 % SoC erreicht" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
					echo "Beende Sofort Laden an Ladepunkt 2 da  $sofortsoclp2 % erreicht"
					fi
				fi
			else
				runs/set-current.sh "$llneu" s1
				echo "$date LP2, Lademodus Sofort. Ladung geändert auf $llneu Ampere" >> ramdisk/ladestatus.log
			fi
		fi
		if (( lademstats1 == 1 )); then	
			if (( $(echo "$aktgeladens1 > $lademkwhs1" |bc -l) )); then
				if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatuss1"; then
					runs/set-current.sh 0 s1
					echo "$date LP2, Lademodus Sofort. Ladung gstoppt da $lademkwhs1 kWh erreicht" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Beende Sofort Laden an Ladepunkt 2 da  $lademkwhs1 kWh erreicht"
					fi
				fi
			else
				runs/set-current.sh "$llneus1" s1
				echo "$date LP2, Lademodus Sofort. Ladung geändert auf $llneus1 Ampere" >> ramdisk/ladestatus.log
			fi
		fi
		if (( sofortsoctatlp2 == 0)) && (( lademstats1 == 0));then
			runs/set-current.sh "$llneus1" s1
			echo "$date LP2, Lademodus Sofort. Ladung geändert auf $llneus1 Ampere" >> ramdisk/ladestatus.log
		fi
		if [[ $lastmanagements2 == "1" ]]; then
			aktgeladens2=$(<ramdisk/aktgeladens2)
			if (( lademstats2 == "1" )) && (( $(echo "$aktgeladens2 > $lademkwhs2" |bc -l) )); then
				if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatuss2"; then
					runs/set-current.sh 0 s2
					echo "$date LP3, Lademodus Sofort. Ladung gestoppt da $lademkwhs2 kWh erreicht" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Beende Sofort Laden an Ladepunkt 3 da  $lademkwhs2 kWh erreicht"
					fi
				fi
			else
				runs/set-current.sh "$llneus2" s2
				echo "$date LP3, Lademodus Sofort. Ladung geändert auf $llneus2 Ampere" >> ramdisk/ladestatus.log

			fi
		fi
		if [[ $lastmanagementlp4 == "1" ]]; then
			llneulp4=$((llaltlp4 - maxdiff))
			if (( llneulp4 < minimalstromstaerke )); then
				llneulp4=$minimalstromstaerke
				if [[ $debug == "1" ]]; then
					echo Ladepunkt 4 Differenz groesser als minimalstromstaerke, setze auf minimal A $minimalstromstaerke
				fi
			fi
			aktgeladenlp4=$(<ramdisk/aktgeladenlp4)
			if (( lademstatlp4 == "1" )) && (( $(echo "$aktgeladenlp4 > $lademkwhlp4" |bc -l) )); then
				if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatuslp4"; then
					runs/set-current.sh 0 lp4
					echo "$date LP4, Lademodus Sofort. Ladung gestoppt da $lademkwhlp4 kWh erreicht" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Beende Sofort Laden an Ladepunkt 4 da  $lademkwhlp4 kWh erreicht"
					fi
				fi
			else
				runs/set-current.sh "$llneulp4" lp4
				echo "$date LP4, Lademodus Sofort. Ladung geändert auf $llneulp4 Ampere" >> ramdisk/ladestatus.log

			fi

		fi
		if [[ $lastmanagementlp5 == "1" ]]; then
			llneulp5=$((llaltlp5 - maxdiff))
			if (( llneulp5 < minimalstromstaerke )); then
				llneulp5=$minimalstromstaerke
				if [[ $debug == "1" ]]; then
					echo Ladepunkt 5 Differenz groesser als minimalstromstaerke, setze auf minimal A $minimalstromstaerke
				fi
			fi
			aktgeladenlp5=$(<ramdisk/aktgeladenlp5)
			if (( lademstatlp5 == "1" )) && (( $(echo "$aktgeladenlp5 > $lademkwhlp5" |bc -l) )); then
				if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatuslp5"; then
					runs/set-current.sh 0 lp5
					echo "$date LP5, Lademodus Sofort. Ladung gestoppt da $lademkwhlp5 kWh erreicht" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Beende Sofort Laden an Ladepunkt 5 da  $lademkwhlp5 kWh erreicht"
					fi
				fi
			else
				runs/set-current.sh "$llneulp5" lp5
				echo "$date LP5, Lademodus Sofort. Ladung geändert auf $llneulp5 Ampere" >> ramdisk/ladestatus.log

			fi

		fi
		if [[ $lastmanagementlp6 == "1" ]]; then
			llneulp6=$((llaltlp6 - maxdiff))
			if (( llneulp6 < minimalstromstaerke )); then
				llneulp6=$minimalstromstaerke
				if [[ $debug == "1" ]]; then
					echo Ladepunkt 6 Differenz groesser als minimalstromstaerke, setze auf minimal A $minimalstromstaerke
				fi
			fi
			aktgeladenlp6=$(<ramdisk/aktgeladenlp6)
			if (( lademstatlp6 == "1" )) && (( $(echo "$aktgeladenlp6 > $lademkwhlp6" |bc -l) )); then
				if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatuslp6"; then
					runs/set-current.sh 0 lp6
					echo "$date LP6, Lademodus Sofort. Ladung gestoppt da $lademkwhlp6 kWh erreicht" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Beende Sofort Laden an Ladepunkt 6 da  $lademkwhlp6 kWh erreicht"
					fi
				fi
			else
				runs/set-current.sh "$llneulp6" lp6
				echo "$date LP6, Lademodus Sofort. Ladung geändert auf $llneulp6 Ampere" >> ramdisk/ladestatus.log

			fi

		fi
		if [[ $lastmanagementlp7 == "1" ]]; then
			llneulp7=$((llaltlp7 - maxdiff))
			if (( llneulp7 < minimalstromstaerke )); then
				llneulp7=$minimalstromstaerke
				if [[ $debug == "1" ]]; then
					echo Ladepunkt 7 Differenz groesser als minimalstromstaerke, setze auf minimal A $minimalstromstaerke
				fi
			fi
			aktgeladenlp7=$(<ramdisk/aktgeladenlp7)
			if (( lademstatlp7 == "1" )) && (( $(echo "$aktgeladenlp7 > $lademkwhlp7" |bc -l) )); then
				if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatuslp7"; then
					runs/set-current.sh 0 lp7
					echo "$date LP7, Lademodus Sofort. Ladung gestoppt da $lademkwhlp7 kWh erreicht" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Beende Sofort Laden an Ladepunkt 7 da  $lademkwhlp7 kWh erreicht"
					fi
				fi
			else
				runs/set-current.sh "$llneulp7" lp7
				echo "$date LP7, Lademodus Sofort. Ladung geändert auf $llneulp7 Ampere" >> ramdisk/ladestatus.log

			fi

		fi
		if [[ $lastmanagementlp8 == "1" ]]; then
			llneulp8=$((llaltlp8 - maxdiff))
			if (( llneulp8 < minimalstromstaerke )); then
				llneulp8=$minimalstromstaerke
				if [[ $debug == "1" ]]; then
					echo Ladepunkt 8 Differenz groesser als minimalstromstaerke, setze auf minimal A $minimalstromstaerke
				fi
			fi
			aktgeladenlp8=$(<ramdisk/aktgeladenlp8)
			if (( lademstatlp8 == "1" )) && (( $(echo "$aktgeladenlp8 > $lademkwhlp8" |bc -l) )); then
				if grep -q 1 "/var/www/html/openWB/ramdisk/ladestatuslp8"; then
					runs/set-current.sh 0 lp8
					echo "$date LP8, Lademodus Sofort. Ladung gestoppt da $lademkwhlp8 kWh erreicht" >> ramdisk/ladestatus.log
					if [[ $debug == "1" ]]; then
						echo "Beende Sofort Laden an Ladepunkt 8 da  $lademkwhlp8 kWh erreicht"
					fi
				fi
			else
				runs/set-current.sh "$llneulp8" lp8
				echo "$date LP8, Lademodus Sofort. Ladung geändert auf $llneulp8 Ampere" >> ramdisk/ladestatus.log

			fi

		fi
		if [[ $debug == "1" ]]; then
			echo "Sofort ladung um $maxdiff auf $llneu reduziert"
		fi
		exit 0		
	fi
fi
}
