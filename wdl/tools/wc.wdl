task wc {
    File in_file
    command {
        cat ${in_file} | wc -l
    }
    output {
        Int count = read_int(stdout())
    }
    runtime {
        docker: "ubuntu:18.04"
        cpu: "1"
        memory: "1 GB"
  }
}

workflow test{
    call wc
}