package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.config;

import java.util.Map;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.DirectExchange;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.rabbit.connection.CachingConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

	@Value("${spring.rabbitmq.host:rabbitmq}")
	private String rabbitHost;

	@Value("${spring.rabbitmq.port:5672}")
	private int rabbitPort;

	@Value("${spring.rabbitmq.username:guest}")
	private String rabbitUsername;

	@Value("${spring.rabbitmq.password:guest}")
	private String rabbitPassword;

	public static final String MAIN_QUEUE = "myQueue";
	public static final String DLX_EXCHANGE = "dlx-exchange";
	public static final String DLX_QUEUE = "dlx-queue";
	public static final String DLX_ROUTING_KEY = "dlx-routing-key";
	
	// Price change monitoring constants
	public static final String PRICE_CHANGE_QUEUE = "price-changes";
	public static final String PRICE_CHANGE_EXCHANGE = "price-change-exchange";
	public static final String PRICE_CHANGE_ROUTING_KEY = "price.change";
	public static final String PRICE_CHANGE_DLX = "price-change-dlx";
	public static final String PRICE_CHANGE_DLQ = "price-change-dlq";

	@Bean
	Jackson2JsonMessageConverter messageConverter() {

		return new Jackson2JsonMessageConverter();
	}

	@Bean
	CachingConnectionFactory connectionFactory() {

		CachingConnectionFactory factory = new CachingConnectionFactory();
		factory.setHost(rabbitHost);
		factory.setPort(rabbitPort);
		factory.setUsername(rabbitUsername);
		factory.setPassword(rabbitPassword);
		return factory;
	}

	@Bean
	Queue myQueue() {

		return new Queue(MAIN_QUEUE, true, false, false,
				Map.of("x-dead-letter-exchange", DLX_EXCHANGE, "x-dead-letter-routing-key", DLX_ROUTING_KEY));
	}

	@Bean
	DirectExchange dlxExchange() {

		return new DirectExchange(DLX_EXCHANGE);
	}

	@Bean
	Queue dlxQueue() {

		return new Queue(DLX_QUEUE);
	}

	@Bean
	Binding dlxBinding() {

		return BindingBuilder.bind(dlxQueue()).to(dlxExchange()).with(DLX_ROUTING_KEY);
	}

	// Price change queue configuration
	@Bean
	Queue priceChangeQueue() {

		return new Queue(PRICE_CHANGE_QUEUE, true, false, false,
				Map.of("x-dead-letter-exchange", PRICE_CHANGE_DLX, "x-dead-letter-routing-key", "dlq"));
	}

	@Bean
	DirectExchange priceChangeExchange() {

		return new DirectExchange(PRICE_CHANGE_EXCHANGE);
	}

	@Bean
	Binding priceChangeBinding() {

		return BindingBuilder.bind(priceChangeQueue()).to(priceChangeExchange()).with(PRICE_CHANGE_ROUTING_KEY);
	}

	// Price change dead letter configuration
	@Bean
	DirectExchange priceChangeDlxExchange() {

		return new DirectExchange(PRICE_CHANGE_DLX);
	}

	@Bean
	Queue priceChangeDlq() {

		return new Queue(PRICE_CHANGE_DLQ);
	}

	@Bean
	Binding priceChangeDlxBinding() {

		return BindingBuilder.bind(priceChangeDlq()).to(priceChangeDlxExchange()).with("dlq");
	}

	@Bean
	public RabbitTemplate rabbitTemplate(CachingConnectionFactory connectionFactory, Jackson2JsonMessageConverter messageConverter) {
	    RabbitTemplate template = new RabbitTemplate(connectionFactory);
	    template.setMessageConverter(messageConverter);
	    return template;
	}
}
