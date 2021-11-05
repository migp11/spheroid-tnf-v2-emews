for i in instance_*
do 
	C=$(tail -1 $i/metrics.txt | cut -f2)
	echo $C $i
done > summary.txt
