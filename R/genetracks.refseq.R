#' refseq
#'
#' @keywords internal
#'
#'@return internal function.
#' 
####checks###

genetracks.refseq <- function(){
    library(rtracklayer)
    ##chromosome = 'X'
    ##start.position = 33031597
    ##end.position = 35051570

    ##get the chromosome number
    ##chrom.number <- gsub("[^[:digit:]]", "", chromosome)
    ##create a range object
    myrange <- GRanges(paste0("chr",chromosome), IRanges(start.position,end.position))

    ##query
    mysession = browserSession("UCSC")
    genome(mysession) <- genome

    mytable <- getTable(ucscTableQuery(mysession,
                                       track = "refGene",
                                       table="refGene",
                                       range=myrange))

    ##column classes
    mytable$exonStarts <- as.character(mytable$exonStarts)
    mytable$exonEnds <- as.character(mytable$exonEnds)

    ## calculate the length of the transcripts
    mytable$genesize <- with(mytable,txEnd-txStart)
    mytable$midpoint <- with(mytable, txStart + (genesize/2))

    ##make all positive
    mytable$genesize <- with(mytable, ifelse(genesize<0,-genesize,genesize))

    ## sort the table according to txStart position
    mytable <- mytable[order(mytable$txStart),]

    ## list the name2
    name2 <- with(mytable, as.character(name2[!duplicated(name2)]))
    if(stack.level == 1){
        stacks <- rep(-1,length(name2))
    }
    if(stack.level == 2){
        stacks <- rep(c(-1,-2),length(name2))[1:length(name2)]
    }
    if(stack.level == 3){
        stacks <- rep(c(-1,-2,-3), length(name2))[1:length(name2)]
    }
    stack.dfm <- data.frame(name2,stacks)

    ##add to mytable
    mytable <- merge(mytable,stack.dfm,by = "name2", all.x = TRUE, sort = FALSE)
    
    ## split with name2
    mytable.split <- split(mytable, mytable$name2)

    ##get the longest transcript
    mytable.split <- lapply(mytable.split, function(x) {
        return(x[x$genesize == max(x$genesize)[1],])
    })


    genetable <- do.call(rbind,mytable.split)
    genetable <- genetable[!duplicated(genetable$name2),]

    ##melt in to exons
    mytable.split <- lapply(mytable.split, function(x){
        exon.start <- unlist(strsplit(x$exonStarts, split = ","))
        exon.end <- unlist(strsplit(x$exonEnds, split = ","))
        name2 <- rep(x$name2,length(exon.start))
        dfm <- data.frame(name2,exon.start,exon.end)
        dfm.new <- merge(dfm,x,all.x = TRUE)
        return(dfm.new)
    })

    ##combine in to sigle data frame
    exontable <- do.call(rbind,mytable.split)
    ##column classes
    exontable$exon.start <- as.numeric(as.character(exontable$exon.start))
    exontable$exon.end <- as.numeric(as.character(exontable$exon.end))


    ##calculate genetracks size
    genetable$gene.ymax <- genetable$stacks + (gene.width/2)
    genetable$gene.ymin <- genetable$stacks - (gene.width/2)
    exontable$exon.ymax <- exontable$stacks + (exon.width/2)
    exontable$exon.ymin <- exontable$stacks - (exon.width/2)


    ##plot
    p1 <-
        p1+
        geom_rect(data= genetable,
                  aes(xmin = txStart, xmax=txEnd, ymin = gene.ymin,
                      ymax = gene.ymax, fill = as.factor(strand)),inherit.aes = FALSE) +
        geom_rect(data = exontable,
                  aes(xmin=exon.start,xmax=exon.end, ymin = exon.ymin,
                      ymax = exon.ymax, fill = as.factor(strand)),inherit.aes = FALSE) +
        geom_rect(data = genetable,aes(ymin = gene.ymin, ymax = ymax,
                                       xmin = txStart, xmax= txEnd,fill = as.factor(strand)),
                  alpha = 0.05, inherit.aes = FALSE) +
        geom_rect(data = exontable, aes(xmin=exon.start,xmax=exon.end, ymin = exon.ymin,
                                        ymax = ymax, fill = as.factor(strand)), alpha = 0.02,inherit.aes = FALSE) +
        theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
              panel.background = element_blank(),
              axis.line = element_line(colour = "grey")) +
        scale_fill_grey()
    if(stack.level == 1){
        p1 + geom_text(data = genetable,aes(x = midpoint,y=-2, label = name2, angle = 90), size = 2, nudge_x = 0, nudge_y =0,
                  check_overlap = FALSE, inherit.aes = FALSE) +
        ylim(-2,ymax)
    } else {
        p1 + geom_text(data = genetable,aes(x = midpoint,y=-0.3+gene.ymin, label = name2, angle = 0), size = 2, nudge_x = 0, nudge_y =0,
                  check_overlap = FALSE, inherit.aes = FALSE) +
        ylim(-4,ymax)
    }
        
}