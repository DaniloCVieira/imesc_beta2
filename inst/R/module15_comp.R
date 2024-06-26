
#' @importFrom shiny NS tagList
#' @export
#'
#' @noRd

#' @export
module_compare<-list()

#' @export
module_compare$ui<-function(id){
  ns<-NS(id)

  column(12,
         #  uiOutput(ns("bug")),
         #    inline( actionButton(ns("teste_comb"),"SAVE")),
         column(12,class="nav_caret",


                div(
                  style="display: flex",

                  div(
                    hidden(actionButton(ns("comp_prev"),strong("<< 2. Prev"),style="height: 30px")),
                    div(style="padding-top: 20px;max-width: 250px",hidden(div(
                      id=ns("summ_options"),
                      box_caret(ns("box_a"),title="Table options",
                                color="#c3cc74ff",
                                button_title = actionLink(ns('summ_down'),"+ Download table"),

                                div(
                                  pickerInput(ns("summ_pic"),"+ Show:" , choices=NULL),
                                  numericInput(ns('round_summ'),"+ Round",3)

                                ))
                    )),
                    hidden(div(id=ns('graphic_options'),
                               box_caret(ns("box_b"),
                                         color="#c3cc74ff",
                                         title=strong("Plot options:"),
                                         div(
                                           div(
                                             pickerInput(inputId = ns("shape"),
                                                         label = ' + Shape:',
                                                         choices = NULL),
                                             numericInput(ns("point_size"),"+ Point size:", value=1),
                                             numericInput(ns("axis_size"),"+ Axis size:", value=1),
                                             numericInput(ns("label_size"),"+ Label size:", value=1),
                                             numericInput(ns("lwd_size"),"+ Line width:", value=1),
                                             pickerInput(inputId = ns("palette"),
                                                         label = "+ Palette",
                                                         choices =NULL),
                                             uiOutput(ns("comp_downplot"))


                                           ))
                               )))

                    )),
                  tabsetPanel(
                    id=ns("page"),type="hidden",


                    tabPanel("tab1",value=1,
                             div(id=ns("page1"),
                                 div(
                                   h5(strong("1. Select the Datalist")),
                                   pickerInput(ns("data_comp"),NULL,choices=NULL)),
                                 uiOutput(ns("data_comp_out"))
                             )),
                    tabPanel('tab2',value=2,
                             uiOutput(ns("page2_dummy")),
                             div(
                               tabsetPanel(
                                 id=ns("comp_results"),
                                 tabPanel("3.1. Summary",value="tab1",
                                          div(style="overflow-x: scroll",uiOutput(ns('summary')))),
                                 tabPanel("3.2. lattice::bwplot",value="tab2",
                                          uiOutput(ns('plot1'))),
                                 tabPanel("3.3. densityplot",value="tab3",
                                          uiOutput(ns('plot2'))),
                                 tabPanel("3.4. dotplot",value="tab4",
                                          uiOutput(ns('plot3'))),
                                 tabPanel("3.5. parallelplot",value="tab5",
                                          uiOutput(ns('plot4'))),
                                 tabPanel("3.6. splom",value="tab6",
                                          uiOutput(ns('plot5'))),
                                 tabPanel("3.7. P-values (pairwise comparisons)",
                                          value="tab8",
                                          div(style="overflow-x: auto",
                                              uiOutput(ns('plot7'))

                                          ))
                               )




                             )
                    )

                  ),
                  actionButton(ns("comp_next"),strong("3. Next >>"),style="height: 30px")
                )))

}

#' @export
module_compare$server<-function (id,vals,df_colors,newcolhabs,df_symbol){
  moduleServer(id,function(input, output, session){

    ns<-session$ns
    observeEvent(ignoreInit = T,input$teste_comb,{
      savereac()
    })

    observeEvent(vals$newcolhabs,{
      choices =vals$colors_img$val
      choicesOpt = list(content =vals$colors_img$img)
      updatePickerInput(session,'palette',choices=choices,choicesOpt=choicesOpt)
    })

    observeEvent(vals$newcolhabs,{
      choices=df_symbol$val
      choicesOpt = list(content = df_symbol$img)
      updatePickerInput(session,'shape',choices=choices,choicesOpt=choicesOpt)
    })

    savereac<-reactive({



      tosave<-isolate(reactiveValuesToList(vals))
      tosave<-tosave[-which(names(vals)%in%c("saved_data","newcolhabs",'colors_img'))]
      tosave<-tosave[-which(unlist(lapply(tosave,function(x) object.size(x)))>1000)]
      tosave$saved_data<-vals$saved_data
      tosave$newcolhabs<-vals$newcolhabs
      tosave$colors_img<-vals$colors_img

      saveRDS(tosave,"savepoint.rds")
      saveRDS(reactiveValuesToList(input),"input.rds")
      beep()
      #vals<-readRDS("vals.rds")
      #input<-readRDS('input.rds')

    })

    output$bug<-renderUI({
      renderPrint(input$limodels)
    })
    insert_rv<-reactiveValues(page = 1)

    observe({shinyjs::toggle("comp_prev",condition=insert_rv$page>1)})
    observe(shinyjs::toggle("comp_next",condition=insert_rv$page<insert_npages))


    observe({
      shinyjs::toggle('graphic_options',condition=!input$comp_results%in%c("tab1","tab8"))
    })


    observe({
      shinyjs::toggle('result_options',condition=insert_rv$page==2)
    })



    observeEvent(insert_rv$page,{
      updateTabsetPanel(session,'page',selected=as.character(insert_rv$page))
    })

    observeEvent(vals$compare_results,{
      re<-summary(vals$compare_results)
      choices=names(re$statistics)
      updatePickerInput(session,'summ_pic',choices=choices)
    })

    observe({
      condition=input$comp_results%in%c("tab1","tab8")&insert_rv$page!=1
      shinyjs::toggle('summ_options',condition=condition)
    })



    observeEvent(ignoreInit = T,input$palette,{vals$cur_comp_palette<-input$palette})

    observe({
      shinyjs::toggle("plot_options",condition=input$comp_results!=c("tab1","tab8"))
    })


    observe({
      shinyjs::toggle("lwd_size",condition=input$comp_results=="tab5")
    })


    observeEvent(ignoreInit = T,input$shape,{
      vals$comp_shape<-input$shape
    })

    observeEvent(ignoreInit = T,input$comp_downplot,{
      vals$hand_plot<-"Download plot - Model comparation"
      module_ui_figs("downfigs")
      mod_downcenter<-callModule(module_server_figs, "downfigs",  vals=vals)
    })

    output$comp_downplot<-renderUI({

      actionLink(ns('comp_downplot'),"+ Download plot")
    })





    observeEvent(ignoreInit = T,input$comp_results,{
      vals$comp_results<-input$comp_results
    })


    observeEvent(vals$saved_data,{
      updatePickerInput(session,"data_comp",choices=names(vals$saved_data),selected=vals$cur_data)
    })



    observeEvent(vals$modellist,{
      req(length(vals$modellist)>1)
      results<-resamples(vals$modellist)
      vals$compare_results<-results

    })
    output$summary<-renderUI({
      div(
        uiOutput(ns("summ_out"))
      )
    })

    observeEvent(ignoreInit = T,input$summ_down,{
      if(input$comp_results=="tab1"){
        vals$hand_down<-"Model Comparation (summary)"} else if(input$comp_results=="tab8"){
          vals$hand_down<-"Model Comparation (pairwise table)"
        }
      module_ui_downcenter("downcenter")
      mod_downcenter<-callModule(module_server_downcenter, "downcenter",  vals=vals)
    })



    output$summ_out<-renderUI({div(

      inline(DT::dataTableOutput(ns('summ_table')))

    )})

    output$summ_table<-DT::renderDataTable({
      req(input$summ_pic)
      re<-summary(vals$compare_results)
      vals$getsummary_comp<-re$statistics[[input$summ_pic]]
      data.frame(round(vals$getsummary_comp,input$round_summ))

    },options = list(pageLength = 20, info = FALSE,dom = 't'), rownames = TRUE,class ='cell-border compact stripe')

    output$page2_dummy<-renderUI({
      req(input$limodels)
      pic<-input$limodels
      req(length(vals$choices_models_equals)>0)
      choices<-vals$choices_models_equals
      act<-which(choices==input$limodels)

      vals$comp_active<-input[[unlist(lapply(seq_along(names(vals$listamodels)),function(x)paste0("equals",names(vals$liequals)[x])))[act]]]
      modellist<-vals$listamodels[[act]][vals$comp_active]
      vals$modellist<-modellist
      NULL
    })


    observeEvent(ignoreInit = T,input$data_comp,{
      vals$data_comp<-input$data_comp
    })
    getdata_comp<-reactive({
      req(input$data_comp)
      data<-vals$saved_data[[input$data_comp]]
      data
    })



    observe({

      #data<-readRDS("savepoint.rds")$saved_data[["nema_araca"]]
      data<-getdata_comp()
      choices<-
        lapply(available_models,function(x){
          if(check_model(data,x))x
        })



      attributes<-choices[which(unlist(lapply(choices, function(x) !is.null(x))))]
      names(attributes)<-unlist(attributes)
      vals$attributes<-attributes
      validate(need(length(vals$attributes)>0,"No models saved in selected datalist"))
      limodels<-lapply(attributes,function(x) {
        attr(data,x)

      })



      names0<-unlist(lapply(limodels,names))


      limodels<-  unlist(lapply(limodels,function(x){
        lapply(x,function(xx) xx$m)
      }),recursive = F)
      pic<-which(sapply(limodels,function(x) class(x)[1])=="train")
      limodels<-limodels[pic]

      linames<-names0




      resmethos<-unlist(lapply(limodels,function(x) paste0("Type:",x$modelType,"; ","Resamling:",x$control$method,x$control$number,paste0("-",x$control$repeats,"X"))))
      #pic_not<-which(unlist(lapply(limodels,function(x) is.null(x$resample))))
      #if(length(pic_not)>0){limodels<-limodels[-pic_not]}
      liequals<-split(limodels,as.vector(unlist(lapply(limodels,function(x)nrow(x$resample)))))
      liequals<-lapply(liequals,function(x) names(x))
      listamodels<-split(limodels,resmethos)
      listanames<-split(names0,resmethos)
      for(i in 1:length(listamodels)){
        names(listamodels[[i]])<-listanames[[i]]
      }



      vals$choices_models_equals<-names(listamodels)
      vals$listamodels<-listamodels
    })
    observe({

      output$data_comp_out<-renderUI({
        choiceValues<-names(vals$listamodels)
        choiceNames=lapply(seq_along(names(vals$listamodels)),function(x){
          div(uiOutput(ns(paste0('liequals',x))))
        })
        req(length(choiceValues)>0)
        req(length(choiceNames)>0)
        #data<-readRDS("savepoint.rds")$saved_data[["nema_araca"]]
        validate(need(length(vals$attributes)>0,"No models saved in selected datalist"))

        if(!is.null(vals$cur_limodels)){
          if(!vals$cur_limodels%in%choiceValues){
            vals$cur_limodels<-NULL
          }
        }

        div(class='card',style="padding: 20px",


            h5(strong('2. Select the models', tiphelp("Comparisons are only allowed for models with compatible resampling methods."))),
            div(id='comp_choices',
                radioButtons(ns("limodels"), NULL, choiceValues=choiceValues,choiceNames =choiceNames, inline=T, selected=vals$cur_limodels)
            )

        )
      })
    })




    observeEvent(ignoreInit = T,input$limodels,{
      vals$cur_limodels<-input$limodels
    })



    insert_npages<-2
    observeEvent(ignoreInit = T,input$comp_prev, navPage(-1))
    observeEvent(ignoreInit = T,input$comp_next, navPage(1))

    navPage<-function(direction) {
      insert_rv$page<-insert_rv$page + direction
    }

    observe({
      toggleState(id = ns("insert_prev"), condition = insert_rv$page > 1)
      toggleState(id = ns("page1"), condition = insert_rv$page > 1)
      toggleState(id = ns("insert_next"), condition = insert_rv$page < insert_npages)
      toggleState(id = ns("page2"), condition = insert_rv$page < insert_npages)
      hide(selector = ".page")
      shinyjs::show(paste0("insert_step", insert_rv$page))
    })
    observeEvent(ignoreInit = T,input$insert_prev, navPage(-1))
    observeEvent(ignoreInit = T,input$insert_next, navPage(1))


    observe({
      req(input$limodels)
      listamodels<-vals$listamodels
      req(!is.null(listamodels))


      liequals<-lapply(listamodels, names)
      names(liequals)<-1:length(liequals)
      vals$liequals<-liequals
      ress<-list()
      lapply(seq_along(names(listamodels)),function(x){
        output[[paste0('liequals',x)]]<-renderUI({
          div(class='card',h5(strong(names(listamodels)[x])),width=12,
              if(input$limodels==names(listamodels)[x]){
                div(class="comp_models",checkboxGroupInput(ns(paste0("equals",names(liequals)[x])), NULL, choices=liequals[[x]], selected=liequals[[x]]), style="max-width: 190px; white-space: normal;font-size: 12px; padding:0px")
              })
        })
      })

    })

    output$plot1<-renderUI({
      results<-vals$compare_results
      req(!is.null(results))
      renderPlot({
        lattice::trellis.par.set("par.xlab.text",list(cex=input$label_size))
        lattice::trellis.par.set("par.ylab.text",list(cex=input$label_size))
        vals$comp_plot<-lattice::bwplot(results, scales=list(x=list(relation="free",cex=input$axis_size), y=list(relation="free",cex=input$axis_size)),cex=input$point_size, pch=as.numeric(input$shape))
        vals$comp_plot
      })
    })
    output$plot2<-renderUI({
      #vals<-readRDS("vals.rds")
      #input<-readRDS("input.rds")
      results<-vals$compare_results
      req(!is.null(results))
      req(input$palette)
      renderPlot({
        lattice::trellis.par.set("par.xlab.text",list(cex=input$label_size))
        lattice::trellis.par.set("par.ylab.text",list(cex=input$label_size))
        scales<-list(x=list(relation="free",cex=input$axis_size), y=list(relation="free",cex=input$axis_size))
        vals$comp_plot<-lattice::densityplot(
          results,
          scales=scales,
          cex=input$point_size,
          par.settings = list(superpose.line = list(col = getcolhabs(vals$newcolhabs,input$palette,length(vals$modellist)))),
          pch=as.numeric(input$shape),
          auto.key =T
        )
        vals$comp_plot
      })
    })
    output$plot3<-renderUI({
      results<-vals$compare_results
      req(!is.null(results))
      renderPlot({
        lattice::trellis.par.set(caretTheme())
        lattice::trellis.par.set("par.xlab.text",list(cex=input$label_size))
        lattice::trellis.par.set("par.ylab.text",list(cex=input$label_size))
        scales<-list(x=list(relation="free",cex=input$axis_size), y=list(relation="free",cex=input$axis_size))
        vals$comp_plot<-lattice::dotplot(results, scales=scales,cex=input$point_size, pch=as.numeric(input$shape))
        vals$comp_plot})

    })
    output$plot4<-renderUI({
      results<-vals$compare_results
      req(!is.null(results))
      div(
        renderPlot({
          lattice::trellis.par.set("par.xlab.text",list(cex=input$label_size))
          lattice::trellis.par.set("par.ylab.text",list(cex=input$label_size))

          lattice::trellis.par.set("axis.text",list(cex=input$axis_size))
          # lattice::trellis.par.set("par.xlab.text",mt)
          # #lattice::trellis.par.set("par.ylab.text",mt)
          vals$comp_plot<- lattice::parallelplot(results,cex=input$point_size,pch=as.numeric(input$shape), lwd=input$lwd_size, auto.key =T, par.settings = list(superpose.line = list(col = getcolhabs(vals$newcolhabs,input$palette,length(vals$modellist)))))
          vals$comp_plot
        })
      )
    })
    output$plot5<-renderUI({
      results<-vals$compare_results
      req(!is.null(results))
      renderPlot(
        {
          lattice::trellis.par.set("par.xlab.text",list(cex=input$label_size))
          lattice::trellis.par.set("par.ylab.text",list(cex=input$label_size))
          #lattice::trellis.par.set("par.ylab.text",mt)
          vals$comp_plot<- lattice::splom(results,cex=input$point_size, scales=list(x=list(cex=input$axis_size), y=list(cex=input$axis_size)),pch=as.numeric(input$shape))
          vals$comp_plot}
      )
    })
    output$plot7<-renderUI({
      results<-vals$compare_results
      req(!is.null(results))

      diffs<-diff(results)

      reprint<-re<-summary(diffs)


      reprint$call<-NULL
      reprint$table<-NULL
      reprint<- capture.output(reprint)


      res<-apply(data.frame(re$table[[input$summ_pic]]),2,function(x)as.numeric(x))
      colnames(res)<-colnames(re$table[[input$summ_pic]])
      rownames(res)<-rownames(re$table[[input$summ_pic]])
      vals$getsummary_comp<-res


      res<-round(vals$getsummary_comp, input$round_summ)
      div(class="half-drop-inline",

          fixed_dt(res,scrollY = "200px")
          ,
          lapply(reprint[ which(!reprint%in%c("Call:","","NULL"))],function(x) div(em(x)))
      )


    })
    output$plot6<-renderUI({
      req(!is.null(vals$modellist))
      div(
        span(
          inline(
            div(style="max-width: 200px; min-width: 50px",
                div("X"),
                div(pickerInput(ns("model_X"),NULL, choices=names(vals$modellist)))
            )
          ),
          inline(
            div(style="max-width: 200px; min-width: 50px",
                div("Y"),
                div(pickerInput(ns("model_Y"),NULL, choices=names(vals$modellist)))
            )
          )
        ),
        uiOutput(ns("modemodel_XY"))


      )
    })
    output$modemodel_XY<-renderUI({
      results<-vals$compare_results
      req(!is.null(results))
      renderPlot({
        lattice::trellis.par.set("par.xlab.text",list(cex=input$label_size))
        lattice::trellis.par.set("par.ylab.text",list(cex=input$label_size))
        vals$comp_plot<- lattice::xyplot(results, models=c(input$model_X, input$model_Y),cex=input$point_size,scales=list(x=list(cex=input$axis_size), y=list(cex=input$axis_size)), pch=as.numeric(input$shape))
        vals$comp_plot
      })

    })





  })}
